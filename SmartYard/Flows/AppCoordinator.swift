//
//  AppCoordinator.swift
//  SmartYard
//
//  Created by admin on 28/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import XCoordinator
import AVKit
import RxSwift
import RxCocoa
import Kingfisher
import UserNotifications
import linphonesw

enum AppRoute: Route {
    
    case main
    case incomingCall(callPayload: CallPayload)
    case dismiss
    case userName(preloadedName: APIClientName?)
    case phoneNumber
    case pinCode(phoneNumber: String, isInitial: Bool)
    case alert(title: String, message: String?)

    case newPersonTestRoute(delegate: NewAllowedPersonViewModelDelegate, personType: AllowedPersonType)
    
}

class AppCoordinator: NavigationCoordinator<AppRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let linphoneService = LinphoneService()
    private let apiService = APIService()
    private var accessService = AccessService()
    private let apiWrapper: APIWrapper
    
    private var mainTabBarRouter: StrongRouter<MainTabBarRoute>?
    
    private var currentCallPreviewData: Data?
    
    init() {
        let accessService = AccessService()
        
        apiWrapper = APIWrapper(apiService: apiService, accessService: accessService)
        self.accessService = accessService
        
        super.init(initialRoute: .phoneNumber/*accessService.routeForCurrentState*/)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
        
        observeLogout()
    }
    
    override func prepareTransition(for route: AppRoute) -> NavigationTransition {
        switch route {
        case .main:
            let router = MainTabBarCoordinator(accessService: accessService, apiWrapper: apiWrapper)
                .strongRouter
            
            mainTabBarRouter = router
            return .set([router], animation: .fade)
            
        case let .incomingCall(callPayload):
            let vm = IncomingCallViewModel(
                linphoneService: linphoneService,
                callPayload: callPayload,
                router: weakRouter
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
            
        case let .newPersonTestRoute(delegate, personType):
            let vm = NewAllowedPersonViewModel(
                router: weakRouter,
                delegate: delegate,
                allowedPersonType: personType
            )
            
            let vc = NewAllowedPersonViewController(viewModel: vm)
            vc.modalPresentationStyle = .overCurrentContext
            
            return .present(vc)
        }
    }
    
    func activateToken(token: String, tokenType: TokenType) {
        // TODO: Update token activation logic
    }
    
    private func observeLogout() {
        NotificationCenter.default.rx.notification(.init("UserLoggedOut"))
            .subscribe(
                onNext: { [weak self] _ in
                    self?.trigger(.phoneNumber)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
