//
//  SettingsCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import XCoordinator
import SafariServices

enum SettingsRoute: Route {
    
    case main
    case addressSettings(flatId: String, address: String, isContractOwner: Bool, hasDomophone: Bool)
    case back
    case dismiss
    case serviceIsActivated(clientId: String?, address: String)
    case serviceIsNotActivated(service: SettingsServiceType, address: String)
    case serviceUnavailable(service: SettingsServiceType, address: String, clientId: String?)
    case advancedSettings(name: String)
    case addressDeletion(delegate: AddressDeletionViewModelDelegate)
    case alert(title: String, message: String?)
    case dialog(title: String, message: String?, actions: [UIAlertAction])
    case addressAccess(address: String, flatId: String)
    case newAllowedPerson(delegate: NewAllowedPersonViewModelDelegate, personType: AllowedPersonType)
    case safariPage(url: URL)
    
}

class SettingsCoordinator: NavigationCoordinator<SettingsRoute> {
    
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    private let permissionService: PermissionService
    
    init(
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        apiWrapper: APIWrapper,
        issueService: IssueService,
        permissionService: PermissionService
    ) {
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.permissionService = permissionService
        
        super.init(initialRoute: .main)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    override func prepareTransition(for route: SettingsRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = SettingsViewModel(router: weakRouter, apiWrapper: apiWrapper, accessService: accessService)
            let vc = SettingsViewController(viewModel: vm)
            return .set([vc])
            
        case let .addressSettings(flatId, address, isContractOwner, hasDomophone):
            let vm = AddressSettingsViewModel(
                apiWrapper: apiWrapper,
                issueService: issueService,
                flatId: flatId,
                address: address,
                isContractOwner: isContractOwner,
                hasDomophone: hasDomophone,
                router: weakRouter
            )
            
            let vc = AddressSettingsViewController(viewModel: vm)
            return .push(vc)
            
        case .back:
            return .pop()
            
        case .dismiss:
            return .dismiss()
            
        case let .serviceIsActivated(clientId, address):
            let vm = ServiceIsActivatedViewModel(
                router: weakRouter,
                issueService: issueService,
                clientId: clientId,
                address: address
            )
            
            let vc = ServiceIsActivatedViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .serviceIsNotActivated(service, address):
            let vm = ServiceIsNotActivatedViewModel(
                router: weakRouter,
                service: service,
                address: address,
                issueService: issueService
            )
            
            let vc = ServiceIsNotActivatedViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .serviceUnavailable(service, address, clientId):
            let vm = ServiceUnavailableViewModel(
                router: weakRouter,
                service: service,
                address: address,
                issueService: issueService,
                clientId: clientId
            )
            
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
                apiWrapper: apiWrapper,
                permissionService: permissionService
            )
            
            let vc = AddressAccessViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .safariPage(url):
            let vc = SFSafariViewController(url: url)
            
            return .present(vc)
        
        }
    }
    
}
