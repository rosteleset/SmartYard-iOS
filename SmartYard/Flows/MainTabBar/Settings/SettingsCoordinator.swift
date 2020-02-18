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
    case serviceIsActivated
    case serviceIsNotActivated
    case serviceUnavailable
    case advancedSettings(name: String)
    case addressDeletion(delegate: AddressDeletionViewModelDelegate)
    
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
    
    // swiftlint:disable:next function_body_length
    override func prepareTransition(for route: SettingsRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = SettingsViewModel(router: weakRouter)
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
            
        case .serviceIsActivated:
            let vm = ServiceIsActivatedViewModel(router: weakRouter)
            
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
            let vm = AdvancedSettingsViewModel(router: weakRouter, name: name)
            let vc = AdvancedSettingsViewController(viewModel: vm)
            return .push(vc)
            
        case let .addressDeletion(delegate):
            let vm = AddressDeletionViewModel(router: weakRouter, delegate: delegate)
            
            let vc = AddressDeletionViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
        }
    }
    
}
