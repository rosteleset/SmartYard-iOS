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
    case alert(title: String, message: String)
    case contractPay(items: [PaymentAddressItem])
    case back
    
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
            let vm = PaymentsViewModel(apiWrapper: apiWrapper, router: weakRouter)
            let vc = PaymentsViewController(viewModel: vm)
            return .set([vc])
            
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case .contractPay(let items):
            let vm = PayContractViewModel(items: items, apiWrapper: apiWrapper, router: weakRouter)
            let vc = PayContractViewController(viewModel: vm)
            return .push(vc)
            
        case .back:
            return .pop(animation: .default)
        }
    }
    
}
