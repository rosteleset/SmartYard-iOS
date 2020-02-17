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
    case pinCode(phoneNumber: String)
    
}

class AppCoordinator: NavigationCoordinator<AppRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let linphoneService = LinphoneService()
    private let apiService = APIService()
    private let accessService: AccessService
    private let apiWrapper: APIWrapper
    
    private var mainTabBarRouter: StrongRouter<MainTabBarRoute>?
    
    private var currentCallPreviewData: Data?
    
    init() {
        let accessService = AccessService()
        
        apiWrapper = APIWrapper(apiService: apiService, accessService: accessService)
        self.accessService = accessService
        
        let initialState: AppRoute = {
            guard accessService.accessToken != nil else {
                return .phoneNumber
            }
            
            guard accessService.clientName != nil else {
                return .userName(preloadedName: nil)
            }
            
            return .main
        }()
        
        super.init(initialRoute: initialState)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: AppRoute) -> NavigationTransition {
        switch route {
        case .main:
            let router = MainTabBarCoordinator(
                apiWrapper: apiWrapper
            ).strongRouter
            
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
            let vm = UserNameViewModel(apiWrapper: apiWrapper, router: weakRouter)
            let vc = UserNameViewController(viewModel: vm, preloadedName: preloadedName)
            return .set([vc], animation: .fade)
            
        case .phoneNumber:
            let vm = InputPhoneNumberViewModel(apiWrapper: apiWrapper, router: weakRouter)
            let vc = InputPhoneNumberViewController(viewModel: vm)
            return .set([vc], animation: .fade)
            
        case let .pinCode(phoneNumber):
            let vm = PinCodeViewModel(apiWrapper: apiWrapper, router: weakRouter, phoneNumber: phoneNumber)
            let vc = PinCodeViewController(viewModel: vm)
            return .set([vc], animation: .fade)
        }
    }
    
    func activateToken(token: String, tokenType: TokenType) {
        // TODO: Update logic
//        Completable
//            .concat(
//                apiWrapper.registerToken(pushToken: token, type: tokenType),
//                apiWrapper.updateTokenState(pushToken: token, newState: .on)
//            )
//            .andThen(
//                apiWrapper.checkTokenState(pushToken: token)
//            )
//            .subscribe(
//                onSuccess: { data in
//                    print("DEBUG / \(tokenType) \(token) is now \(data.state)")
//                },
//                onError: { error in
//                    print(error)
//                }
//            )
//            .disposed(by: disposeBag)
    }
    
}
