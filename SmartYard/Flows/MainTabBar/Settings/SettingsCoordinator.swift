//
//  SettingsCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import XCoordinator

enum SettingsRoute: Route {
    
    case main
    case addressSettings
    
}

class SettingsCoordinator: NavigationCoordinator<SettingsRoute> {
    
    let apiWrapper: APIWrapper
    
    init(
        apiWrapper: APIWrapper
    ) {
        self.apiWrapper = apiWrapper
        super.init(initialRoute: .main)
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: SettingsRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = SettingsViewModel()
            let vc = SettingsViewController(viewModel: vm)
            return .set([vc])
            
        case .addressSettings:
            let vm = AddressSettingsViewModel()
            let vc = AddressSettingsViewController(viewModel: vm)
            return .push(vc)
        }
    }
    
}
