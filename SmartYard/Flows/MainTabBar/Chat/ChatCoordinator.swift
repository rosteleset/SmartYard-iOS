//
//  ChatCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import XCoordinator

enum ChatRoute: Route {
    case main
}

class ChatCoordinator: NavigationCoordinator<ChatRoute> {
    
    private let accessService: AccessService
    
    init(accessService: AccessService) {
        self.accessService = accessService
        
        super.init(initialRoute: .main)
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: ChatRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vc = ChatViewController(userPhone: accessService.clientPhoneNumber)
            return .set([vc])
        }
    }
    
}
