// Created by Александр Попов. Copyright © 2026 Sesameware.

import UIKit
import XCoordinator
import RxSwift
import RxCocoa
import SwifterSwift
import AVKit
import SmartYardSharedDataFramework
import Kingfisher

extension AppCoordinator {
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func makeTransition(for route: AppRoute) -> NavigationTransition {
        switch route {
        case .main:
            configureBackendMonitoring()
            let coordinator = MainTabBarCoordinator(
                accessService: accessService,
                pushNotificationService: pushNotificationService,
                apiWrapper: apiWrapper,
                issueService: issueService,
                permissionService: permissionService,
                alertService: alertService,
                logoutHelper: logoutHelper,
                offlineAddressListDataSource: offlineAddressListDataSource,
                networkStateProvider: networkStateProvider,
                optionsService: optionsService,
                supportCallActionsPresenter: supportCallActionsPresenter,
                requestSupportCallbackUseCase: requestSupportCallbackUseCase,
                phoneDialer: phoneDialer
            )

            mainTabBarCoordinator = coordinator

            return .set([coordinator], animation: .fade)

        case .dismiss:
            return .dismiss()

        case let .webView(url):
            let coordinator = WebViewCoordinator(
                rootVC: rootViewController,
                apiWrapper: apiWrapper,
                networkStateProvider: networkStateProvider,
                url: url,
                backButtonLabel: L10n.Common.back,
                push: true,
                version: 2
            )

            webViewCoordinator = coordinator
            addChild(coordinator)
            return .none()

        case let .userName(preloadedName):
            let vm = UserNameViewModel(
                accessService: accessService,
                apiWrapper: apiWrapper,
                logoutHelper: logoutHelper,
                alertService: alertService,
                router: weakRouter
            )

            let vc = UserNameViewController(viewModel: vm, preloadedName: preloadedName)
            return .set([vc], animation: .fade)

        case .phoneNumber:
            let vm = InputPhoneNumberViewModel(
                accessService: accessService,
                apiWrapper: apiWrapper,
                router: weakRouter
            )

            let vc = InputPhoneNumberViewController(viewModel: vm)
            return .set([vc], animation: .fade)

        case let .pinCode(phoneNumber, isInitial, useFlashCall):
            let vm = PinCodeViewModel(
                accessService: accessService,
                alertService: alertService,
                apiWrapper: apiWrapper,
                router: weakRouter,
                phoneNumber: phoneNumber
            )

            let vc = PinCodeViewController(viewModel: vm, isInitial: isInitial, useFlashCall: useFlashCall)
            return .set([vc], animation: .fade)

        case let .authByOutgoingCall(phoneNumber: phoneNumber, confirmPhoneNumber: confirmPhone):
            let vm = OutgoingCallViewModel(
                accessService: accessService,
                alertService: alertService,
                apiWrapper: apiWrapper,
                router: weakRouter,
                phoneNumber: phoneNumber,
                confirmPhone: confirmPhone
            )

            let vc = OutgoingCallViewController(viewModel: vm)
            return .set([vc], animation: .fade)

        case let .alert(title, message):
            return .alertTransition(title: title, message: message)

        case let .dialog(title, message, actions):
            return .dialogTransition(title: title, message: message, actions: actions)

        case .onboarding:
            let vm = OnboardingViewModel(router: weakRouter, accessService: accessService)
            let vc = OnboardingViewController(viewModel: vm)
            return .set([vc], animation: .fade)

        case let .appSettings(title, message):
            return .appSettingsTransition(title: title, message: message)

        case let .incomingCall(callPayload, isCallKitUsed, actionIdentifier, completionHandler):
            // MARK: чтобы окно входящего вызова не показывалось до того, как пользователь
            // ответит на вызов в CallKit, показываем экран входящего вызова только после ответа.
            NotificationCenter.default.rx
                .notification(.answeredByCallKit, object: nil)
                .asDriverOnErrorJustComplete()
                .drive(
                    onNext: { [weak self] _ in
                        guard let self, incomingCallPortraitVC != nil else { return }
                        shouldPresentIncomingCallWindow = true
                        configureIncomingCallWindowIfNeeded()
                    }
                )
                .disposed(by: disposeBag)

            let vm = IncomingCallViewModel(
                providerProxy: providerProxy,
                linphoneService: linphoneService,
                permissionService: permissionService,
                apiWrapper: apiWrapper,
                pushNotificationService: pushNotificationService,
                router: weakRouter,
                callPayload: callPayload,
                isCallKitUsed: isCallKitUsed,
                actionIdentifier: actionIdentifier,
                completionHandler: completionHandler
            )

            let landscapeVC = IncomingCallLandscapeViewController(viewModel: vm)
            landscapeVC.loadViewIfNeeded()
            self.incomingCallLandscapeVC = landscapeVC

            let portraitVC = IncomingCallPortraitViewController(viewModel: vm)
            portraitVC.loadViewIfNeeded()
            self.incomingCallPortraitVC = portraitVC

            shouldPresentIncomingCallWindow =
                IncomingCallRoutingPolicy.presentation(useCallKit: isCallKitUsed) == .immediately
            configureIncomingCallWindowIfNeeded()

            return .none()

        case .closeIncomingCall:
            if let portraitVC = incomingCallPortraitVC {
                incomingCallWindow?.switchRootViewController(to: portraitVC)
            }

            incomingCallWindow?.isHidden = true
            incomingCallWindow = nil
            shouldPresentIncomingCallWindow = false
            incomingCallPortraitVC = nil
            incomingCallLandscapeVC = nil
            temporarilyIgnoredOrientation = nil

            DispatchQueue.main.async { [weak self] in
                self?.mainWindow?.makeKeyAndVisible()
            }

            return .none()

        case let .paranoidPush(payload):
            let vc = ModalViewController(
                dismissCallback: { [weak self] in self?.trigger(.dismiss) },
                content: .paranoid(payload)
            )
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve

            return .present(vc)

        case let .whatsNew(release):
            let vc = ModalViewController(
                dismissCallback: { [weak self] in
                    guard let self else { return }
                    WhatsNewPresentationStore.markPresented(version: release.version)
                    isWhatsNewPresented = false
                    trigger(.dismiss)
                },
                content: .whatsNew(release)
            )
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve

            return .present(vc)

        case .registerQRCode(code: let code):
            let qrType = AnalyticsValue.qrType(from: code)
            logQRCodeScannedFromDeeplink(qrType: qrType)

            switch accessService.appState {
            case .main:
                break
            default:
                logQRCodeGrantFailedFromDeeplink(qrType: qrType, errorCode: "login_required")
                self.trigger(.alert(
                    title: L10n.Address.QRCode.loginRequiredMessage,
                    message: nil
                ))
                return .none()
            }

            let activityTracker = ActivityTracker()
            let errorTracker = ErrorTracker()

            self.apiWrapper
                .registerQR(qr: code)
                .do(
                    onSuccess: { [weak self] _ in
                        self?.logQRCodeGrantSuccessFromDeeplink(qrType: qrType)
                    },
                    onError: { [weak self] error in
                        self?.logQRCodeGrantFailedFromDeeplink(
                            qrType: qrType,
                            errorCode: AnalyticsError.code(from: error)
                        )
                    }
                )
                .trackActivity(activityTracker)
                .trackError(errorTracker)
                .asDriverOnErrorJustComplete()
                .drive()
                .disposed(by: disposeBag)

            errorTracker
                .asDriver()
                .drive { [weak self] error in
                    self?.trigger(.alert(title: error.localizedDescription, message: nil))
                    self?.apiWrapper.forceUpdateAddress = true
                    self?.apiWrapper.forceUpdateSettings = true
                    self?.apiWrapper.forceUpdatePayments = true
                    NotificationCenter.default.post(name: .addressAdded, object: nil)
                }
                .disposed(by: disposeBag)

            return .none()

        case .selectProvider:
            let vm = SelectProviderViewModel(
                apiWrapper: apiWrapper,
                alertService: alertService,
                accessService: accessService,
                router: weakRouter
            )
            let vc = SelectProviderViewController(viewModel: vm)
            return .set([vc], animation: .fade)

        case .offline:
            let vm = HomeOfflineViewModel(
                accessService: accessService,
                offlineAddressListDataSource: offlineAddressListDataSource,
                networkStateProvider: networkStateProvider,
                router: weakRouter
            )
            let vc = HomeOfflineViewController(viewModel: vm)

            return .present(vc, animation: .default)

        case .dismissOffline:
            isOfflinePresented = false
            accessService.appState = .main
            return .dismiss()
        }
    }
}
