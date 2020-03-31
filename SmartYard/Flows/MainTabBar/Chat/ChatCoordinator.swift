//
//  ChatCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

enum ChatRoute: Route {
    case main
}

class ChatCoordinator: NavigationCoordinator<ChatRoute> {
    
    private let disposeBag = DisposeBag()
    private let accessService: AccessService
    
    private var chatVm: ChatViewModel?
    
    init(accessService: AccessService) {
        self.accessService = accessService
        
        super.init(initialRoute: .main)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
        
        subscribeToChatNotifications()
    }
    
    override func prepareTransition(for route: ChatRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = ChatViewModel(accessService: accessService)
            chatVm = vm
            
            let vc = ChatViewController(viewModel: vm)
            return .set([vc])
        }
    }
    
    private func subscribeToChatNotifications() {
        NotificationCenter.default.rx.notification(.chatRequested)
            .asDriverOnErrorJustComplete()
            .map { notification -> String? in
                notification.userInfo?[NotificationKeys.clientIdKey] as? String
            }
            .drive(
                onNext: { [weak self] clientId in
                    self?.chatVm?.updateClientId(clientId)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
