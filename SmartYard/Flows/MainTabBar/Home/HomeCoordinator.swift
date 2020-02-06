//
//  HomeCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import XCoordinator

enum HomeRoute: Route {
    case main
}

class HomeCoordinator: NavigationCoordinator<HomeRoute> {
    
    let apiWrapper: APIWrapper
    
    init(
        apiWrapper: APIWrapper
    ) {
        self.apiWrapper = apiWrapper
        super.init(initialRoute: .main)
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: HomeRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = AddressesViewModel()
            let vc = AddressesViewController(viewModel: vm)
            return .set([vc])
        }
    }
    
}
