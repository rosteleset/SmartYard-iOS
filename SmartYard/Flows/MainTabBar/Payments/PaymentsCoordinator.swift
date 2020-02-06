//
//  PaymentsCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import XCoordinator

enum PaymentsRoute: Route {
    case main
}

class PaymentsCoordinator: NavigationCoordinator<PaymentsRoute> {
    
    let apiWrapper: APIWrapper
    
    init(
        apiWrapper: APIWrapper
    ) {
        self.apiWrapper = apiWrapper
        super.init(initialRoute: .main)
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: PaymentsRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = PaymentsViewModel()
            let vc = PaymentsViewController(viewModel: vm)
            return .set([vc])
        }
    }
    
}
