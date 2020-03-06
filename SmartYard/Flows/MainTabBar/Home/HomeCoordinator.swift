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
    case alert(title: String, message: String?)
    case inputContract
    case inputAddress
    case availableServices(address: String)
    case unavailabeServices
    case confirmAddress
    
}

class HomeCoordinator: NavigationCoordinator<HomeRoute> {
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let issueService: IssueService
    
    init(
        apiWrapper: APIWrapper,
        pushNotificationService: PushNotificationService,
        accessService: AccessService,
        issueService: IssueService
    ) {
        self.apiWrapper = apiWrapper
        self.pushNotificationService = pushNotificationService
        self.accessService = accessService
        self.issueService = issueService
        
        super.init(initialRoute: .main)
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: HomeRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = AddressesListViewModel(
                apiWrapper: apiWrapper,
                pushNotificationService: pushNotificationService,
                router: weakRouter
            )
            
            let vc = AddressesListViewController(viewModel: vm)
            return .set([vc])
            
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case .inputContract:
            let vm = AuthByContractNumViewModel(
                router: weakRouter,
                issueService: issueService,
                apiWrapper: apiWrapper
            )
            
            let vc = AuthByContractNumViewController(viewModel: vm)
            
            return .set([vc], animation: .fade)
            
        case .inputAddress:
            let vm = InputAddressViewModel(
                router: weakRouter,
                apiWrapper: apiWrapper
            )
            
            let vc = InputAddressViewController(viewModel: vm)
            
            return .set([vc], animation: .fade)
            
        case let .availableServices(address):
            let vm = AvailableSericesViewModel(router: weakRouter, apiWrapper: apiWrapper, address: address)
            let vc = AvailableServicesViewController(viewModel: vm)
            
            return .set([vc], animation: .fade)
            
        case .unavailabeServices:
            let vm = ServicesActivationRequestViewModel(router: weakRouter, apiWrapper: apiWrapper)
            let vc = ServicesActivationRequestViewController(viewModel: vm)
            
            return .set([vc], animation: .fade)
            
        case .confirmAddress:
            let vm = AddressConfirmationViewModel(
                router: weakRouter,
                apiWrapper: apiWrapper,
                issueService: issueService
            )
            
            let vc = AddressConfirmationViewController(viewModel: vm)
            
            return .set([vc], animation: .fade)
        }
    }
    
}
