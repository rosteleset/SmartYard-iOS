//
//  PaymentsCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import XCoordinator
import SafariServices

enum PaymentsRoute: Route {
    
    case main
    case alert(title: String, message: String)
    case contractPay(address: String, items: [APIPaymentsListAccount])
    case back
    case safariPage(url: URL)
    case paymentPopup(apiWrapper: APIWrapper, clientId: String)
    
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
            
        case let .contractPay(address, items):
            let vm = PayContractViewModel(
                address: address,
                items: items,
                apiWrapper: apiWrapper,
                router: weakRouter
            )
            
            let vc = PayContractViewController(viewModel: vm)
            return .push(vc)
            
        case .back:
            return .pop(animation: .default)
            
        case let .paymentPopup(apiWrapper, clientId):
            let vm = PaymentPopupViewModel(apiWrapper: apiWrapper, clientId: clientId)
            let vc = PaymentPopupController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            
            return .present(vc)
            
        case let .safariPage(url):
            let vc = SFSafariViewController(url: url)
            return .present(vc)
        }
    }
    
}
