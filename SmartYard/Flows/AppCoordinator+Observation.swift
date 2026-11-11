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
    func observeLogout() {
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
    func observeOrientationChanges() {
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

    func observeAccessService() {
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
            .subscribe(with: self) { owner, _ in
                owner.setCrashlyticsUserID()
                owner.optionsService.forceReload(reason: .didAuthorize)
                owner.presentWhatsNewIfNeeded()
            }
            .disposed(by: disposeBag)
    }

    func observeNetworkEvents() {
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
            presentWhatsNewIfNeeded()
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

    func syncOfflinePresentationOnLaunch() {
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

    func configureBackendMonitoring() {
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
    }

    private func makeHealthURL() -> URL? {
        guard let base = URL(string: accessService.backendURL) else { return nil }
        return base.appendingPathComponent("ext/options")
    }

    func resolveBaseURLIfNeeded() {
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
}
