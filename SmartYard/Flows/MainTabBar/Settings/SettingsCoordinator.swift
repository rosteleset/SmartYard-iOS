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
    case addressSettings(address: String)
    case back
    case dismiss
    case serviceIsActivated(clientId: String?)
    case serviceIsNotActivated
    case serviceUnavailable
    case advancedSettings(name: String)
    case addressDeletion(delegate: AddressDeletionViewModelDelegate)
    case alert(title: String, message: String?)
    case dialog(title: String, message: String?, actions: [UIAlertAction])
    case addressAccess(address: String, flatId: String)
    case newAllowedPerson(delegate: NewAllowedPersonViewModelDelegate, personType: AllowedPersonType)
    
}

class SettingsCoordinator: NavigationCoordinator<SettingsRoute> {
    
    let accessService: AccessService
    let pushNotificationService: PushNotificationService
    let apiWrapper: APIWrapper
    let issueService: IssueService
    
    init(
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        apiWrapper: APIWrapper,
        issueService: IssueService
    ) {
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        
        super.init(initialRoute: .main)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    override func prepareTransition(for route: SettingsRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = SettingsViewModel(router: weakRouter, apiWrapper: apiWrapper)
            let vc = SettingsViewController(viewModel: vm)
            return .set([vc])
            
        case let .addressSettings(address):
            let vm = AddressSettingsViewModel(router: weakRouter, address: address)
            let vc = AddressSettingsViewController(viewModel: vm)
            return .push(vc)
            
        case .back:
            return .pop()
            
        case .dismiss:
            return .dismiss()
            
        case let .serviceIsActivated(clientId):
            let vm = ServiceIsActivatedViewModel(
                router: weakRouter,
                issueService: issueService,
                clientId: clientId
            )
            
            let vc = ServiceIsActivatedViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case .serviceIsNotActivated:
            let vm = ServiceIsNotActivatedViewModel(router: weakRouter)
            
            let vc = ServiceIsNotActivatedViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case .serviceUnavailable:
            let vm = ServiceUnavailableViewModel(router: weakRouter)
            
            let vc = ServiceUnavailableViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .advancedSettings(name):
            let vm = AdvancedSettingsViewModel(
                accessService: accessService,
                pushNotificationService: pushNotificationService,
                router: weakRouter,
                name: name
            )
            
            let vc = AdvancedSettingsViewController(viewModel: vm)
            return .push(vc)
            
        case let .addressDeletion(delegate):
            let vm = AddressDeletionViewModel(router: weakRouter, delegate: delegate)
            
            let vc = AddressDeletionViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case let .dialog(title, message, actions):
            return .dialogTransition(title: title, message: message, actions: actions)
            
        case let .newAllowedPerson(delegate, personType):
            let vm = NewAllowedPersonViewModel(
                router: weakRouter,
                delegate: delegate,
                allowedPersonType: personType
            )
            
            let vc = NewAllowedPersonViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .addressAccess(address, flatId):
            let vm = AddressAccessViewModel(
                router: weakRouter,
                address: address,
                flatId: flatId,
                apiWrapper: apiWrapper
            )
            
            let vc = AddressAccessViewController(viewModel: vm)
            
            return .push(vc)
        }
    }
    
}
