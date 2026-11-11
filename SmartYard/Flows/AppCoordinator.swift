//
//  AppCoordinator.swift
//  SmartYard
//
//  Created by admin on 28/01/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
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
    case webView(url: URL)
    case appSettings(title: String, message: String?)
    case registerQRCode(code: String)
    case incomingCall(
        callPayload: CallPayload,
        isCallKitUsed: Bool,
        actionIdentifier: String = "",
        completionHandler: (() -> Void)? = nil
    )
    case closeIncomingCall
    case paranoidPush(payload: ParanoidPushPayload)
    case whatsNew(release: WhatsNewRelease)
    
}

// swiftlint:disable:next type_body_length
final class AppCoordinator: NavigationCoordinator<AppRoute>, HasDisposeBag {
    
    let linphoneService: LinphoneService
    let providerProxy: CXProviderProxy
    
    let accessService: AccessService
    let permissionService: PermissionService
    let apiWrapper: APIWrapper
    let issueService: IssueService
    let pushNotificationService: PushNotificationService
    let alertService: AlertService
    private let telemetryService: AppTelemetryServicing
    let logoutHelper: LogoutHelper
    private let debugNetwork: DebugNetworkController
    let networkEnv: NetworkEnvironment
    let networkStateProvider: NetworkStateProviding
    let offlineAddressListDataSource: OfflineAddressListDataSource
    let optionsService: OptionsServicing
    let supportCallActionsPresenter: SupportCallActionsPresenting
    let requestSupportCallbackUseCase: RequestSupportCallbackUseCase
    let phoneDialer: PhoneDialing

#if DEBUG
    private lazy var debugOverlay = DebugNetworkOverlay(controller: debugNetwork)
#endif

    var mainTabBarCoordinator: MainTabBarCoordinator?
    
    private var currentCallPreviewData: Data?
    
    weak var mainWindow: UIWindow?
    
    var incomingCallWindow: UIWindow?
    var shouldPresentIncomingCallWindow = false
    var incomingCallLandscapeVC: IncomingCallLandscapeViewController?
    var incomingCallPortraitVC: IncomingCallPortraitViewController?
    
    var temporarilyIgnoredOrientation: UIDeviceOrientation?
    
    var selectedTabPresentable: Presentable? {
        mainTabBarCoordinator?.selectedPresentable
    }

    var webViewCoordinator: WebViewCoordinator?
    var isOfflinePresented = false
    private var didLoadOptionsOnce = false
    private var isLoadingOptions = false
    private var pendingParanoidPushPayload: ParanoidPushPayload?
    var isWhatsNewPresented = false

    init(dependencies: AppDependencies) {
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
    
    func connect(to window: UIWindow) {
        mainWindow = window
        setRoot(for: window)
        configureIncomingCallWindowIfNeeded()
    }

    func disconnect(from window: UIWindow) {
        guard mainWindow === window else { return }
        mainWindow = nil
        incomingCallWindow?.isHidden = true
        incomingCallWindow?.windowScene = nil
        incomingCallWindow = nil
#if DEBUG
        debugOverlay.hide()
#endif
    }

    func configureIncomingCallWindowIfNeeded() {
        guard let windowScene = mainWindow?.windowScene,
              let portraitVC = incomingCallPortraitVC else { return }

        if incomingCallWindow == nil {
            incomingCallWindow = UIWindow(windowScene: windowScene)
        }

        incomingCallWindow?.overrideUserInterfaceStyle = Constants.isDarkModeEnabled
            ? ThemeManager.shared.currentTheme.value
            : .light

        if shouldPresentIncomingCallWindow {
            incomingCallWindow?.rootViewController = portraitVC
            incomingCallWindow?.makeKeyAndVisible()
        }
    }

    override func prepareTransition(for route: AppRoute) -> NavigationTransition {
        makeTransition(for: route)
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
        
        let hasEnqueuedCall = linphoneService.hasEnqueuedCalls
        let isIgnored = !hasEnqueuedCall
            && pushNotificationService.isCallIgnored(callId: callPayload.uniqueIdentifier)
        let admissionDecision = IncomingCallRoutingPolicy.admission(
            hasEnqueuedCall: hasEnqueuedCall,
            isIgnored: isIgnored
        )

        switch admissionDecision {
        case .rejectAlreadyHandling:
            Logger.logWarning("Cannot process incoming call: already handling another call.")
            return
        case .rejectIgnored:
            Logger.logInfo("Ignored call with ID: \(callPayload.uniqueIdentifier)")
            return
        case .enqueue:
            break
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

    @discardableResult
    func processParanoidPush(
        userInfo: [AnyHashable: Any],
        notificationTitle: String?,
        notificationBody: String?
    ) -> Bool {
        guard let payload = ParanoidPushPayload(
            userInfo: userInfo,
            notificationTitle: notificationTitle,
            notificationBody: notificationBody,
            providerBaseURL: accessService.backendURL,
            serverTimeZone: accessService.timeZone
        ) else {
            return false
        }

        pendingParanoidPushPayload = payload
        presentPendingParanoidPushIfNeeded()
        return true
    }

    func presentPendingParanoidPushIfNeeded() {
        guard let payload = pendingParanoidPushPayload else { return }
        guard mainWindow?.rootViewController != nil else { return }

        pendingParanoidPushPayload = nil

        DispatchQueue.main.async { [weak self] in
            self?.trigger(.paranoidPush(payload: payload))
        }
    }

    func presentWhatsNewIfNeeded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            guard accessService.appState == .main else { return }
            guard mainTabBarCoordinator != nil else { return }
            guard !isWhatsNewPresented else { return }
            guard rootViewController.presentedViewController == nil else { return }
            guard let release = WhatsNewPresentationStore.releaseToPresent() else { return }

            isWhatsNewPresented = true
            trigger(.whatsNew(release: release))
        }
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

    enum AlertNetworkState: Equatable { case online, offline }

    func logQRCodeScannedFromDeeplink(qrType: String) {
        AppAnalytics.log(AppAnalyticsEvent.qrScanSuccess(qrType: qrType, source: "deeplink"))
    }

    func logQRCodeGrantSuccessFromDeeplink(qrType: String) {
        AppAnalytics.log(
            AppAnalyticsEvent.qrAccessGrantSuccess(
                qrType: qrType,
                source: "deeplink"
            )
        )
    }

    func logQRCodeGrantFailedFromDeeplink(qrType: String, errorCode: String?) {
        AppAnalytics.log(
            AppAnalyticsEvent.qrAccessGrantFailed(
                qrType: qrType,
                source: "deeplink",
                errorCode: errorCode
            )
        )
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

    @objc private func toggleDebug() {
        guard let windowScene = mainWindow?.windowScene else { return }
        debugOverlay.toggle(in: windowScene)
    }
#endif
}
