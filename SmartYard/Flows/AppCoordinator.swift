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

enum AppRoute: Route {
    
    case main
    case incomingCall(callPayload: CallPayload)
    
}

class AppCoordinator: NavigationCoordinator<AppRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let apiService = APIService()
    private let apiWrapper: APIWrapper
    
    init() {
        apiWrapper = APIWrapper(apiService: apiService)
        
        super.init(initialRoute: .main)
        rootViewController.setNavigationBarHidden(true, animated: false)
        
        AVCaptureDevice.requestAccess(for: .video) { _ in }
    }
    
    override func prepareTransition(for route: AppRoute) -> NavigationTransition {
        switch route {
        case .main:
            return .none()
            
        case let .incomingCall(callPayload):
            let vm = IncomingCallPreviewViewModel(callPayload: callPayload)
            let vc = IncomingCallPreviewViewController(viewModel: vm)
            return .present(vc)
        }
    }
    
    func activateToken(token: String, tokenType: TokenType) {
        Completable
            .concat(
                apiWrapper.sendToken(token: token, tokenType: tokenType),
                apiWrapper.updateTokenState(token: token, isEnabled: true),
                apiWrapper.checkTokenState(token: token)
            )
            .subscribe(
                onCompleted: {
                    print("DEBUG / \(tokenType) \(token) is now ACTIVE")
                },
                onError: { error in
                    print(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
    func showIncomingCall(callPayload: CallPayload) {
        trigger(.incomingCall(callPayload: callPayload))
    }
    
}
