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
import FirebaseCrashlytics

enum AppRoute: Route {
    
    case main
    case dismiss
    case userName(preloadedName: APIClientName?)
    case phoneNumber
    case selectProvider
    case pinCode(phoneNumber: String, isInitial: Bool)
    case authByOutgoingCall(phoneNumber: String, confirmPhoneNumber: String)
    case alert(title: String, message: String?)
    case onboarding
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
class AppCoordinator: NavigationCoordinator<AppRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let linphoneService = LinphoneService()
    private let providerProxy = CXProviderProxy()
    
    private let accessService = AccessService()
    private let permissionService = PermissionService()
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    private let pushNotificationService: PushNotificationService
    private let alertService = AlertService()
    private let logoutHelper: LogoutHelper
    
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
    
    init(mainWindow: UIWindow) {
        apiWrapper = APIWrapper(accessService: accessService)
        issueService = IssueService(apiWrapper: apiWrapper, accessService: accessService)
        pushNotificationService = PushNotificationService(apiWrapper: apiWrapper)
        
        logoutHelper = LogoutHelper(
            pushNotificationService: pushNotificationService,
            accessService: accessService,
            alertService: alertService
        )
        
        self.mainWindow = mainWindow
        
        // блокируем основной поток до обновления baseUrl из списка провайдеров если провайдер был выбран.
        switch accessService.appState {
        case .onboarding, .selectProvider:
            break
        default:
            updateBaseUrlSync(apiWrapper: apiWrapper, accessService: accessService)
        }
        
        super.init(initialRoute: accessService.routeForCurrentState)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
        
        observeLogout()
        observeOrientationChanges()
    }
    
    // swiftlint:disable:next function_body_length
    override func prepareTransition(for route: AppRoute) -> NavigationTransition {
        switch route {
        case .main:
            let coordinator = MainTabBarCoordinator(
                accessService: accessService,
                pushNotificationService: pushNotificationService,
                apiWrapper: apiWrapper,
                issueService: issueService,
                permissionService: permissionService,
                alertService: alertService,
                logoutHelper: logoutHelper
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
            
        case let .pinCode(phoneNumber, isInitial):
            let vm = PinCodeViewModel(
                accessService: accessService,
                apiWrapper: apiWrapper,
                router: weakRouter,
                phoneNumber: phoneNumber
            )
            
            let vc = PinCodeViewController(viewModel: vm, isInitial: isInitial)
            return .set([vc], animation: .fade)
        
        case let .authByOutgoingCall(phoneNumber: phoneNumber, confirmPhoneNumber: confirmPhone):
            let vm = OutgoingCallViewModel(
                accessService: accessService,
                apiWrapper: apiWrapper,
                router: weakRouter,
                phoneNumber: phoneNumber,
                confirmPhone: confirmPhone
            )
            
            let vc = OutgoingCallViewController(viewModel: vm)
            return .set([vc], animation: .fade)
            
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
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
                self.trigger(.alert(title: "Сначала авторизуйтесь в приложении, а затем повторите попытку добавить адрес", message: nil))
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
                router: weakRouter)
            let vc = SelectProviderViewController(viewModel: vm)
            return .set([vc], animation: .fade)
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
            print("Can only process one call at a time")
            return
        }
        
        guard !pushNotificationService.isCallIgnored(callId: callPayload.uniqueIdentifier) else {
            print("Call was ignored")
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
            handle: "Входящий звонок",
            hasVideo: true,
            completion: callKitCompletion
        )
        
        providerProxy.endCall(uuid: uuid)
    }
    
    func setVoipToken(_ token: String) {
        accessService.voipToken = token
    }
    
    func setCrashlyticsUserID() {
        Crashlytics.crashlytics().setUserID(accessService.clientPhoneNumber ?? "unknown")
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
                    print("DEBUG: Successfully subscribed to push notifications")
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
        
        // и меняем URL на новый в общем файле - чтобы и виджет работал с новым URL
        guard var sharedData = SmartYardSharedDataUtilities.loadSharedData() else {
            return
        }
        sharedData.backendURL = newBackendURL
        SmartYardSharedDataUtilities.saveSharedData(data: sharedData)
    }
    
    func openNotificationsTab() {
        // MARK: DispatchAsync - потому что если вызывать эту штуку сразу при запуске, таббара еще не будет
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.mainTabBarCoordinator?.trigger(.notifications)
        }
    }
    
    func openChatTab() {
        // MARK: DispatchAsync - потому что если вызывать эту штуку сразу при запуске, таббара еще не будет
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.mainTabBarCoordinator?.trigger(.chat)
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
                    
                    self?.trigger(.selectProvider)
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
    
}

private func updateBaseUrlSync(apiWrapper: APIWrapper, accessService: AccessService) {
    let sem = DispatchSemaphore(value: 0)
    let disposeBag = DisposeBag()
    
    apiWrapper.getProvidersList()
        .catchAndReturn(nil)
        .asObservable()
        .subscribe(
            onNext: { response in
                guard let provList = response,
                let prov = provList.first(where: { $0.id == accessService.providerId }) else {
                    sem.signal()
                    return
                }
                
                accessService.backendURL = prov.baseUrl
                sem.signal()
            }
        )
        .disposed(by: disposeBag)
    sem.wait()
}
