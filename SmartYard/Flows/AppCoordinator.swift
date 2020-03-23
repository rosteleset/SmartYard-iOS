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

enum AppRoute: Route {
    
    case main
    case incomingCall(callPayload: CallPayload)
    case dismiss
    case userName(preloadedName: APIClientName?)
    case phoneNumber
    case pinCode(phoneNumber: String, isInitial: Bool)
    case alert(title: String, message: String?)
    
}

class AppCoordinator: NavigationCoordinator<AppRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let linphoneService = LinphoneService()
    private let accessService = AccessService()
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    private let pushNotificationService: PushNotificationService
    
    private var mainTabBarRouter: StrongRouter<MainTabBarRoute>?
    
    private var currentCallPreviewData: Data?
    
    init() {
        apiWrapper = APIWrapper(accessService: accessService)
        issueService = IssueService(apiWrapper: apiWrapper, accessService: accessService)
        pushNotificationService = PushNotificationService(apiWrapper: apiWrapper)
        
        super.init(initialRoute: accessService.routeForCurrentState)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
        
        observeLogout()
    }
    
    // swiftlint:disable:next function_body_length
    override func prepareTransition(for route: AppRoute) -> NavigationTransition {
        switch route {
        case .main:
            let router = MainTabBarCoordinator(
                accessService: accessService,
                pushNotificationService: pushNotificationService,
                apiWrapper: apiWrapper,
                issueService: issueService
            ).strongRouter
            
            mainTabBarRouter = router
            return .set([router], animation: .fade)
            
        case let .incomingCall(callPayload):
            let vm = IncomingCallViewModel(
                linphoneService: linphoneService,
                apiWrapper: apiWrapper,
                router: weakRouter,
                callPayload: callPayload
            )
            
            let vc = IncomingCallViewController(viewModel: vm)
            
            vc.modalPresentationStyle = .overFullScreen
            vc.modalPresentationCapturesStatusBarAppearance = true
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case .dismiss:
            return .dismiss()
            
        case let .userName(preloadedName):
            let vm = UserNameViewModel(accessService: accessService, apiWrapper: apiWrapper, router: weakRouter)
            let vc = UserNameViewController(viewModel: vm, preloadedName: preloadedName)
            return .set([vc], animation: .fade)
            
        case .phoneNumber:
            let vm = InputPhoneNumberViewModel(accessService: accessService, apiWrapper: apiWrapper, router: weakRouter)
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
        }
    }
    
    func processIncomingCallRequest(callPayload: CallPayload) {
        // MARK: Проверяем, есть ли у нас уже входящие звонки на данный момент
        // Скорее всего, дальше надо будет делать какую-то очередь, но сейчас для демо и так сгодится
        
        guard !linphoneService.hasEnqueuedCalls else {
            print("Can only process one call at a time")
            return
        }
        
        linphoneService.hasEnqueuedCalls = true
        trigger(.incomingCall(callPayload: callPayload))
    }
    
    private func observeLogout() {
        NotificationCenter.default.rx.notification(.init("UserLoggedOut"))
            .subscribe(
                onNext: { [weak self] _ in
                    if let mainTabBarRouter = self?.mainTabBarRouter {
                        self?.removeChild(mainTabBarRouter)
                        self?.mainTabBarRouter = nil
                    }
                    
                    self?.trigger(.phoneNumber)
                }
            )
            .disposed(by: disposeBag)
    }
    
}

