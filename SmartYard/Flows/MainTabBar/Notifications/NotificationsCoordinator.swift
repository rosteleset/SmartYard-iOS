//
//  NotificationsCoordinator.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import XCoordinator

enum NotificationsRoute: Route {
    
    case main
    case alert(title: String, message: String?)
    case share(items: [Any])
    
}

class NotificationsCoordinator: NavigationCoordinator<NotificationsRoute> {
    
    private let apiWrapper: APIWrapper
    private let pushNotificationService: PushNotificationService
    
    init(apiWrapper: APIWrapper, pushNotificationService: PushNotificationService) {
        self.apiWrapper = apiWrapper
        self.pushNotificationService = pushNotificationService
        
        super.init(initialRoute: .main)
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: NotificationsRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = NotificationsViewModel(
                apiWrapper: apiWrapper,
                pushNotificationService: pushNotificationService,
                router: weakRouter
            )
            
            let vc = NotificationsViewController(viewModel: vm)
            return .set([vc])
            
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case let .share(items):
            return .shareTransition(items: items)
        }
    }
    
}
