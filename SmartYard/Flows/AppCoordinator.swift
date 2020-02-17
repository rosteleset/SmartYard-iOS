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
    case userName
    case phoneNumber
    case pinCode(phoneNumber: String)
    case newPersonTestRoute
    
}

class AppCoordinator: NavigationCoordinator<AppRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let linphoneService = LinphoneService()
    private let apiService = APIService()
    private let accessService = AccessService()
    private let apiWrapper: APIWrapper
    
    private var mainTabBarRouter: StrongRouter<MainTabBarRoute>?
    
    private var currentCallPreviewData: Data?
    
    init() {
        // MARK: Замоканные данные. Убрать после добавления флоу авторизации
        accessService.accessToken = "79902143-88e4-46fd-a2ed-2bd0b132c433:6ebba629d6adbace8fbb974fd0aa4795"
        accessService.clientId = "75549"
        
        apiWrapper = APIWrapper(apiService: apiService, accessService: accessService)
        
        super.init(initialRoute: .phoneNumber)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: AppRoute) -> NavigationTransition {
        switch route {
        case .main:
            let router = MainTabBarCoordinator(
                apiWrapper: apiWrapper
            ).strongRouter
            
            mainTabBarRouter = router
            return .set([router])
            
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
            
        case .userName:
            let vm = UserNameViewModel(router: weakRouter)
            let vc = UserNameViewController(viewModel: vm)
            return .present(vc)
            
        case .phoneNumber:
            let vm = AddressAccessViewModel(router: weakRouter)
            return .present(AddressAccessViewController(viewModel: vm))
//            let vm = InputPhoneNumberViewModel(router: weakRouter)
//            return .present(InputPhoneNumberViewController(viewModel: vm))
            
        case let .pinCode(phoneNumber):
            let vm = PinCodeViewModel(router: weakRouter, phoneNumber: phoneNumber)
            return .present(PinCodeViewController(viewModel: vm))
            
        case .newPersonTestRoute:
            let vm = NewAllowedPersonViewModel(router: weakRouter)
            let vc = NewAllowedPersonViewController(viewModel: vm)
            return .present(vc)
        }
    }
    
    func activateToken(token: String, tokenType: TokenType) {
        Completable
            .concat(
                apiWrapper.registerToken(pushToken: token, type: tokenType),
                apiWrapper.updateTokenState(pushToken: token, newState: .on)
            )
            .andThen(
                apiWrapper.checkTokenState(pushToken: token)
            )
            .subscribe(
                onSuccess: { data in
                    print("DEBUG / \(tokenType) \(token) is now \(data.state)")
                },
                onError: { error in
                    print(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
