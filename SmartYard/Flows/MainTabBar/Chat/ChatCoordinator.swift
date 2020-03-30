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
    
    init() {
        super.init(initialRoute: .main)
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: ChatRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vc = ChatViewController()
            return .set([vc])
        }
    }
    
}
