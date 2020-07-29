//
//  AppCoordinator.swift
//  SmartYard
//
//  Created by admin on 28/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import XCoordinator
import RxSwift
import RxCocoa
import SwifterSwift
import AVKit

enum AppRoute: Route {
    
    case main
    case dismiss
    case userName(preloadedName: APIClientName?)
    case phoneNumber
    case pinCode(phoneNumber: String, isInitial: Bool)
    case alert(title: String, message: String?)
    case onboarding
    case appSettings(title: String, message: String?)
    
    case incomingCall(callPayload: CallPayload, isCallKitUsed: Bool)
    case closeIncomingCall
    
}

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
        return mainTabBarCoordinator?.selectedPresentable
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
            
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case .onboarding:
            let vm = OnboardingViewModel(router: weakRouter, accessService: accessService)
            let vc = OnboardingViewController(viewModel: vm)
            return .set([vc], animation: .fade)
            
        case let .appSettings(title, message):
            return .appSettingsTransition(title: title, message: message)
            
        case let .incomingCall(callPayload, isCallKitUsed):
            let vm = IncomingCallViewModel(
                providerProxy: providerProxy,
                linphoneService: linphoneService,
                permissionService: permissionService,
                apiWrapper: apiWrapper,
                router: weakRouter,
                callPayload: callPayload,
                isCallKitUsed: isCallKitUsed
            )
            
            let landscapeVC = IncomingCallLandscapeViewController(viewModel: vm)
            landscapeVC.loadViewIfNeeded()
            self.incomingCallLandscapeVC = landscapeVC
            
            let portraitVC = IncomingCallPortraitViewController(viewModel: vm)
            portraitVC.loadViewIfNeeded()
            self.incomingCallPortraitVC = portraitVC
            
            incomingCallWindow = UIWindow()
            incomingCallWindow?.rootViewController = portraitVC
            incomingCallWindow?.makeKeyAndVisible()
            
            return .none()
         
        case .closeIncomingCall:
            if let portraitVC = incomingCallPortraitVC {
                incomingCallWindow?.switchRootViewController(to: portraitVC)
            }
            
            incomingCallWindow = nil
            incomingCallPortraitVC = nil
            incomingCallLandscapeVC = nil
            
            DispatchQueue.main.async { [weak self] in
                self?.mainWindow.makeKeyAndVisible()
            }
            
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            
            return .none()
        }
    }
    
    func processIncomingCallRequest(callPayload: CallPayload, useCallKit: Bool) {
        if useCallKit {
            providerProxy.reportIncomingCall(
                uuid: callPayload.uuid,
                handle: callPayload.callerId,
                hasVideo: true
            )
        }
        
        // MARK: Проверяем, есть ли у нас уже входящие звонки на данный момент
        // Скорее всего, дальше надо будет делать какую-то очередь, но сейчас для демо и так сгодится
        
        guard !linphoneService.hasEnqueuedCalls else {
            print("Can only process one call at a time")
            return
        }
        
        linphoneService.hasEnqueuedCalls = true
        
        // MARK: Здесь решил перестраховаться, хотя вроде все и работало раньше
        
        DispatchQueue.main.async { [weak self] in
            self?.trigger(.incomingCall(callPayload: callPayload, isCallKitUsed: useCallKit))
        }
    }
    
    func reportInvalidCall() {
        let uuid = UUID()
        
        providerProxy.reportIncomingCall(
            uuid: uuid,
            handle: "Входящий звонок",
            hasVideo: true
        )
        
        providerProxy.endCall(uuid: uuid)
    }
    
    func setVoipToken(_ token: String) {
        accessService.voipToken = token
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
                    
                    self?.trigger(.phoneNumber)
                }
            )
            .disposed(by: disposeBag)
    }
    
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
