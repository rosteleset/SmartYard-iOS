//
//  AppCoordinator.swift
//  SmartYard
//
//  Created by admin on 28/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import XCoordinator
import RxSwift
import RxCocoa
import SwifterSwift
import AVKit
import SmartYardSharedDataFramework
import Kingfisher

enum AppRoute: Route {
    
    case main
    case dismiss
    case userName(preloadedName: APIClientName?)
    case phoneNumber
    case selectProvider
    case pinCode(phoneNumber: String, isInitial: Bool, useFlashCall: Bool)
    case authByOutgoingCall(phoneNumber: String, confirmPhoneNumber: String)
    case alert(title: String, message: String?)
    case dialog(title: String, message: String?, actions: [UIAlertAction])
    case onboarding
    case offline
    case dismissOffline
    case appSettings(title: String, message: String?)
    case registerQRCode(code: String)
    case incomingCall(
        callPayload: CallPayload,
        isCallKitUsed: Bool,
        actionIdentifier: String = "",
        completionHandler: (() -> Void)? = nil
    )
    case closeIncomingCall
    
}

// swiftlint:disable:next type_body_length
final class AppCoordinator: NavigationCoordinator<AppRoute>, HasDisposeBag {
    
    
    private let linphoneService: LinphoneService
    private let providerProxy: CXProviderProxy
    
    private let accessService: AccessService
    private let permissionService: PermissionService
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    private let pushNotificationService: PushNotificationService
    private let alertService: AlertService
    private let telemetryService: AppTelemetryServicing
    private let logoutHelper: LogoutHelper
    private let debugNetwork: DebugNetworkController
    private let networkEnv: NetworkEnvironment
    private let networkStateProvider: NetworkStateProviding
    private let offlineAddressListDataSource: OfflineAddressListDataSource
    private let optionsService: OptionsServicing
    private let supportCallActionsPresenter: SupportCallActionsPresenting
    private let requestSupportCallbackUseCase: RequestSupportCallbackUseCase
    private let phoneDialer: PhoneDialing

#if DEBUG
    private lazy var debugOverlay = DebugNetworkOverlay(controller: debugNetwork)
#endif

    private var mainTabBarCoordinator: MainTabBarCoordinator?
    
    private var currentCallPreviewData: Data?
    
    private let mainWindow: UIWindow
    
    private var incomingCallWindow: UIWindow?
    private var incomingCallLandscapeVC: IncomingCallLandscapeViewController?
    private var incomingCallPortraitVC: IncomingCallPortraitViewController?
    
    private var temporarilyIgnoredOrientation: UIDeviceOrientation?
    
    var selectedTabPresentable: Presentable? {
        mainTabBarCoordinator?.selectedPresentable
    }

    private var isOfflinePresented = false
    private var didLoadOptionsOnce = false
    private var isLoadingOptions = false

    init(mainWindow: UIWindow, dependencies: AppDependencies) {
        self.linphoneService = dependencies.linphoneService
        self.providerProxy = dependencies.providerProxy
        self.accessService = dependencies.accessService
        self.permissionService = dependencies.permissionService
        self.apiWrapper = dependencies.apiWrapper
        self.issueService = dependencies.issueService
        self.pushNotificationService = dependencies.pushNotificationService
        self.alertService = dependencies.alertService
        self.telemetryService = dependencies.telemetryService
        self.logoutHelper = dependencies.logoutHelper
        self.debugNetwork = dependencies.debugNetwork
        self.networkEnv = dependencies.networkEnv
        self.networkStateProvider = dependencies.networkStateProvider
        self.offlineAddressListDataSource = dependencies.offlineAddressListDataSource
        self.optionsService = dependencies.optionsService
        self.supportCallActionsPresenter = dependencies.supportCallActionsPresenter
        self.requestSupportCallbackUseCase = dependencies.requestSupportCallbackUseCase
        self.phoneDialer = dependencies.phoneDialer
        self.mainWindow = mainWindow

        super.init(initialRoute: accessService.routeForCurrentState)

        resolveBaseURLIfNeeded()
        syncOfflinePresentationOnLaunch()
        optionsService.loadIfNeeded(reason: .coldStart)

#if DEBUG
        setupDebugGesture()
#endif

        rootViewController.setNavigationBarHidden(true, animated: false)
        
        observeLogout()
        observeOrientationChanges()
        observeNetworkEvents()
        observeAccessService()
    }
    
    // swiftlint:disable cyclomatic_complexity function_body_length
    override func prepareTransition(for route: AppRoute) -> NavigationTransition {
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
                        guard let self = self,
                              let vc = self.incomingCallPortraitVC else {
                            return
                        }
                        self.incomingCallWindow?.rootViewController = vc
                        self.incomingCallWindow?.makeKeyAndVisible()
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
            
            incomingCallWindow = UIWindow()

            if Constants.isDarkModeEnabled {
                let currentTheme = ThemeManager.shared.currentTheme.value
                let userInterfaceStyle: UIUserInterfaceStyle

                switch currentTheme {
                case .unspecified:
                    switch UITraitCollection.current.userInterfaceStyle {
                    case .dark:
                        userInterfaceStyle = .dark
                    case .light:
                        userInterfaceStyle = .light
                    default:
                        userInterfaceStyle = .unspecified
                    }
                case .light:
                    userInterfaceStyle = .light
                case .dark:
                    userInterfaceStyle = .dark
                @unknown default:
                    userInterfaceStyle = .unspecified
                }

                incomingCallWindow?.overrideUserInterfaceStyle = userInterfaceStyle
            } else {
                incomingCallWindow?.overrideUserInterfaceStyle = .light
            }

            // MARK: Если вызов пришёл обычным пуш-уведомлением, то показываем экран входящего вызова
            if !isCallKitUsed {
                incomingCallWindow?.rootViewController = portraitVC
                incomingCallWindow?.makeKeyAndVisible()
            }
            
            return .none()
         
        case .closeIncomingCall:
            if let portraitVC = incomingCallPortraitVC {
                incomingCallWindow?.switchRootViewController(to: portraitVC)
            }
            
            incomingCallWindow = nil
            incomingCallPortraitVC = nil
            incomingCallLandscapeVC = nil
            temporarilyIgnoredOrientation = nil
            
            DispatchQueue.main.async { [weak self] in
                self?.mainWindow.makeKeyAndVisible()
            }
            
            return .none()
            
        case .registerQRCode(code: let code):
            
            switch accessService.appState {
            case .main:
                break
            default:
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
    
    func processIncomingCallRequest(
        callPayload: CallPayload,
        useCallKit: Bool,
        callKitCompletion: (() -> Void)? = nil,
        actionIdentifier: String = "",
        completionHandler: (() -> Void)? = nil
    ) {
        if useCallKit, let completion = callKitCompletion {
            providerProxy.reportIncomingCall(
                uuid: callPayload.uuid,
                handle: callPayload.callerId,
                hasVideo: true,
                completion: completion
            )
        }
        
        // MARK: Проверяем, есть ли у нас уже входящие звонки на данный момент
        // Скорее всего, дальше надо будет делать какую-то очередь, но сейчас для демо и так сгодится
        
        guard !linphoneService.hasEnqueuedCalls else {
            Logger.logWarning("Cannot process incoming call: already handling another call.")
            return
        }
        
        guard !pushNotificationService.isCallIgnored(callId: callPayload.uniqueIdentifier) else {
            Logger.logInfo("Ignored call with ID: \(callPayload.uniqueIdentifier)")
            return
        }
        
        linphoneService.hasEnqueuedCalls = true
        
        // MARK: Здесь решил перестраховаться, хотя вроде все и работало раньше
        
        DispatchQueue.main.async { [weak self] in
            self?.trigger(
                .incomingCall(
                    callPayload: callPayload,
                    isCallKitUsed: useCallKit,
                    actionIdentifier: actionIdentifier,
                    completionHandler: completionHandler
                )
            )
        }
    }
    
    func reportInvalidCall(callKitCompletion: @escaping () -> Void) {
        let uuid = UUID()
        
        providerProxy.reportIncomingCall(
            uuid: uuid,
            handle: L10n.Intercom.Incoming.notificationTitle,
            hasVideo: true,
            completion: callKitCompletion
        )
        
        providerProxy.endCall(uuid: uuid)
    }
    
    func setVoipToken(_ token: String) {
        accessService.voipToken = token
    }
    
    func setCrashlyticsUserID() {
        telemetryService.setCrashlyticsUserID(accessService.clientPhoneNumber)
    }
    
    func setAnalyticsOperatorID() {
        telemetryService.setAnalyticsOperator(
            id: accessService.provider.id,
            name: accessService.provider.name
        )
    }

    func markAllMessagesAsDelivered() {
        pushNotificationService.markAllMessagesAsDelivered()
    }
    
    func markMessagesAsDelivered(messageIds: [String]) {
        pushNotificationService.markMessagesAsDelivered(messageIds: messageIds)
    }
    
    func syncBadgeNumber() {
        pushNotificationService.synchronizeBadgeCount()
    }
    
    func updateFCMToken() {
        pushNotificationService
            .registerForPushNotifications(
                voipToken: accessService.prefersVoipForCalls ? accessService.voipToken : nil
            )
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: {
                    Logger.logDebug("Successfully subscribed to push notifications")
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// обновляет URL для обращения к серверу с API
    func updateBackendURL(_ newBackendURL: String) {
        // если он не поменялся, то ничего не делаем
        if accessService.backendURL == newBackendURL {
            return
        }
        
        // иначе меняем URL на новый в приложении
        accessService.backendURL = newBackendURL

        configureBackendMonitoring()

        // и меняем URL на новый в общем файле - чтобы и виджет работал с новым URL
        guard var sharedData = SmartYardSharedDataUtilities.loadSharedData() else {
            return
        }
        sharedData.backendURL = newBackendURL
        SmartYardSharedDataUtilities.saveSharedData(data: sharedData)
    }
    
    func openNotificationsTab() {
        openMainTab(.notifications)
    }
    
    func openChatTab() {
        openMainTab(.chat)
    }

    func openHomeTab() {
        openMainTab(.home)
    }

    func openPaymentsTab() {
        openMainTab(.payments)
    }

    func openMenuTab() {
        openMainTab(.menu)
    }

    func openSettingsTab() {
        openMainTab(.settings)
    }

    func openFirstAddressCameras() {
        openViaMainTabBarCoordinator { coordinator in
            coordinator.openFirstAddressCameras()
        }
    }

    func openFirstAddressEvents() {
        openViaMainTabBarCoordinator { coordinator in
            coordinator.openFirstAddressEvents()
        }
    }

    func openFirstAddressAccess() {
        openViaMainTabBarCoordinator { coordinator in
            coordinator.openFirstAddressAccess()
        }
    }

    // MARK: - Private methods

    private func openMainTab(_ route: MainTabBarRoute) {
        // DispatchAsync - потому что если вызывать эту штуку сразу при запуске, таббара еще не будет
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.mainTabBarCoordinator?.trigger(route)
        }
    }

    private func openViaMainTabBarCoordinator(_ action: @escaping (MainTabBarCoordinator) -> Void) {
        // DispatchAsync - потому что если вызывать эту штуку сразу при запуске, таббара еще не будет
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let coordinator = self?.mainTabBarCoordinator else {
                return
            }
            action(coordinator)
        }
    }

    private func observeLogout() {
        NotificationCenter.default.rx.notification(.init("UserLoggedOut"))
            .subscribe(
                onNext: { [weak self] _ in
                    if let mainTabBarCoordinator = self?.mainTabBarCoordinator {
                        self?.removeChild(mainTabBarCoordinator)
                        self?.mainTabBarCoordinator = nil
                    }

                    self?.networkEnv.backend.setEnabled(false)
                    self?.networkEnv.backend.updateHealthURL(nil)
                    try? self?.offlineAddressListDataSource.wipeCache()

                    ImageCache.default.clearMemoryCache()
                    ImageCache.default.clearDiskCache()
                    
                    self?.trigger(Constants.defaultBackendURL.isNilOrEmpty ? .selectProvider : .phoneNumber)
                }
            )
            .disposed(by: disposeBag)
    }
    
    // swiftlint:disable:next function_body_length
    private func observeOrientationChanges() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        NotificationCenter.default.rx
            .notification(UIDevice.orientationDidChangeNotification)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self,
                        UIDevice.current.orientation != self.temporarilyIgnoredOrientation,
                        let incomingCallWindow = self.incomingCallWindow,
                        let landscapeVC = self.incomingCallLandscapeVC,
                        let portraitVC = self.incomingCallPortraitVC else {
                        return
                    }
                    
                    self.temporarilyIgnoredOrientation = nil
                    
                    if UIDevice.current.orientation == .portrait,
                        incomingCallWindow.rootViewController === landscapeVC {
                        incomingCallWindow.switchRootViewController(to: portraitVC, animated: false)
                        return
                    }
                    
                    if [.landscapeLeft, .landscapeRight].contains(UIDevice.current.orientation),
                        incomingCallWindow.rootViewController === portraitVC {
                        incomingCallWindow.switchRootViewController(to: landscapeVC, animated: false)
                        return
                    }
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.incomingCallForceLandscape)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self,
                        let incomingCallWindow = self.incomingCallWindow,
                        let landscapeVC = self.incomingCallLandscapeVC else {
                        return
                    }
                    
                    self.temporarilyIgnoredOrientation = UIDevice.current.orientation
                    
                    incomingCallWindow.switchRootViewController(to: landscapeVC, animated: false)
                }
            )
            .disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(.incomingCallForcePortrait)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self,
                        let incomingCallWindow = self.incomingCallWindow,
                        let portraitVC = self.incomingCallPortraitVC else {
                        return
                    }
                    
                    self.temporarilyIgnoredOrientation = UIDevice.current.orientation
                    
                    incomingCallWindow.switchRootViewController(to: portraitVC, animated: false)
                }
            )
            .disposed(by: disposeBag)
    }

    private func observeAccessService() {
        accessService.providerChanged
            .subscribe { [weak self] _ in
                self?.setAnalyticsOperatorID()
            }
            .disposed(by: disposeBag)
    
        accessService.backendURLChanged
            .subscribe { [weak self] _ in
                self?.optionsService.forceReload(reason: .backendChanged)
            }
            .disposed(by: disposeBag)
    
        accessService.sessionAuthorized
            .subscribe { [weak self] _ in
                self?.setCrashlyticsUserID()
                self?.optionsService.forceReload(reason: .didAuthorize)
            }
            .disposed(by: disposeBag)
    }

    private enum AlertNetworkState: Equatable { case online, offline }

    private func observeNetworkEvents() {
        Logger.logDebug("<<< observeNetworkEvents: subscribed")

        networkStateProvider.state
            .do(onNext: { state in
                Logger.logDebug("<<< networkStateProvider.state emitted: \(state)")
            })
            .map { $0 == .online ? AlertNetworkState.online : .offline }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] state in
                Logger.logDebug("<<< AlertNetworkState: \(state)")
                DispatchQueue.main.async { [weak self] in
                    self?.handleNetworkAlert(state)
                }
            })
            .disposed(by: disposeBag)
    }

    private func handleNetworkAlert(_ state: AlertNetworkState) {
        Logger.logDebug("<<< Network alert: \(state) appState=\(accessService.appState) route=\(accessService.routeForCurrentState)")

        switch state {
        case .online: showOnlineAlert()
        case .offline: showOfflineAlert()
        }
    }

    private func showOfflineAlert() {
        guard accessService.appState == .main else { return }

        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.showOffline()
        }

        alertService.showDialog(
            title: L10n.Offline.Alert.noConnectionTitle,
            message: L10n.Offline.Message.connectionLost,
            preferredStyle: .alert,
            actions: [okAction],
            priority: 1000
        )
    }

    private func showOnlineAlert() {
        guard accessService.appState == .offline else { return }

        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self else { return }
            isOfflinePresented = false
            accessService.appState = .main
            trigger(.dismissOffline)
        }
        let cancelAction = UIAlertAction(
            title: L10n.Common.cancel,
            style: .destructive
        )

        alertService.showDialog(
            title: L10n.Offline.Message.connectionRestored,
            message: L10n.Offline.Alert.switchMode,
            preferredStyle: .alert,
            actions: [okAction, cancelAction],
            priority: 1000
        )
    }

    private func showOffline() {
        guard accessService.appState == .main else { return }
        guard !isOfflinePresented else { return }

        isOfflinePresented = true
        accessService.appState = .offline
        trigger(.offline)
    }

    private func syncOfflinePresentationOnLaunch() {
        guard accessService.hasValidToken else { return }

        networkStateProvider.state
            .debounce(.milliseconds(250), scheduler: MainScheduler.instance)
            .take(1)
            .subscribe(onNext: { [weak self] state in
                guard let self else { return }

                if state != .online {
                    accessService.appState = .offline
                    presentOfflineIfNeeded()
                } else {
                    if accessService.appState == .offline { accessService.appState = .main }
                    isOfflinePresented = false
                }
            })
            .disposed(by: disposeBag)
    }

    private func presentOfflineIfNeeded() {
        guard !isOfflinePresented else { return }
        isOfflinePresented = true
        trigger(.offline)
    }

    private func configureBackendMonitoring() {
        guard accessService.hasValidToken else {
            networkEnv.backend.setEnabled(false)
            networkEnv.backend.updateHealthURL(nil)
            return
        }

        guard let url = makeHealthURL() else {
            networkEnv.backend.setEnabled(false)
            networkEnv.backend.updateHealthURL(nil)
            return
        }

        networkEnv.backend.updateHealthURL(url)
        networkEnv.backend.setEnabled(true)
        networkEnv.backend.reportMaybeAvailable()
    }

    private func makeHealthURL() -> URL? {
        guard let base = URL(string: accessService.backendURL) else { return nil }
        return base.appendingPathComponent("ext/options")
    }

    private func resolveBaseURLIfNeeded() {
        guard Constants.defaultBackendURL.isNilOrEmpty else { return }

        switch accessService.appState {
        case .onboarding, .selectProvider: return
        default: break
        }

        apiWrapper.getProvidersList()
            .timeout(.seconds(3), scheduler: MainScheduler.instance)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] response in
                    guard
                        let self,
                        let provList = response,
                        let prov = provList.first(where: { $0.id == self.accessService.provider.id })
                    else {
                        Logger.logWarning("BaseURL not resolved")
                        return
                    }

                    self.updateBackendURL(prov.baseUrl)
                    Logger.logDebug("BaseURL resolved -> \(prov.baseUrl)")
                },
                onFailure: { error in
                    Logger.logWarning("BaseURL fetch failed: \(error)")
                }
            )
            .disposed(by: disposeBag)
    }

#if DEBUG
    private func setupDebugGesture() {
        let gesture = UITapGestureRecognizer(
            target: self,
            action: #selector(toggleDebug)
        )
        gesture.numberOfTapsRequired = 3
        gesture.numberOfTouchesRequired = 2
        rootViewController.view.addGestureRecognizer(gesture)
    }

    @objc private func toggleDebug() { debugOverlay.toggle() }
#endif
}
