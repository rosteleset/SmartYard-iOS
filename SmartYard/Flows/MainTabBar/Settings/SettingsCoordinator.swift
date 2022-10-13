//
//  SettingsCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import XCoordinator
import SafariServices
//import Lottie

enum SettingsRoute: Route {
    
    case main
    case addressSettings(flatId: String, clientId: String?, address: String, isContractOwner: Bool, hasDomophone: Bool)
    case back
    case dismiss
    case serviceIsActivated(service: SettingsServiceType, contractName: String?, address: String)
    case serviceIsNotActivated(service: SettingsServiceType, contractName: String?, address: String)
    case serviceUnavailable(service: SettingsServiceType, address: String, contractName: String?)
    case advancedSettings
    case addressDeletion(delegate: AddressDeletionViewModelDelegate)
    case alert(title: String, message: String?)
    case dialog(title: String, message: String?, actions: [UIAlertAction])
    case addressAccess(address: String, flatId: String, clientId: String?)
    case newAllowedPerson(delegate: NewAllowedPersonViewModelDelegate, personType: AllowedPersonType)
    case safariPage(url: URL)
    case editName
    case facesSettings(flatId: Int, address: String)
    case showFace(image: UIImage?)
    case deleteFace(image: UIImage?, flatId: Int, faceId: Int)
    case addFace(flatId: Int, address: String)
    case addFaceFromEvent(event: APIPlog)
    case showModal(withContent: ModalContent)
    case deleteFaceFromEvent(event: APIPlog, imageURL: String?)
}

class SettingsCoordinator: NavigationCoordinator<SettingsRoute> {
    
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    private let permissionService: PermissionService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    
    init(
        rootViewController: RootViewController,
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        apiWrapper: APIWrapper,
        issueService: IssueService,
        permissionService: PermissionService,
        logoutHelper: LogoutHelper,
        alertService: AlertService
    ) {
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.permissionService = permissionService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        
        super.init(rootViewController: rootViewController, initialRoute: nil)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    override func prepareTransition(for route: SettingsRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = SettingsViewModel(
                router: weakRouter,
                apiWrapper: apiWrapper,
                accessService: accessService,
                logoutHelper: logoutHelper,
                alertService: alertService
            )
            
            let vc = SettingsViewController(viewModel: vm)
            return .push(vc) // .set([vc])
            
        case let .addressSettings(flatId, clientId, address, isContractOwner, hasDomophone):
            let vm = AddressSettingsViewModel(
                apiWrapper: apiWrapper,
                issueService: issueService,
                logoutHelper: logoutHelper,
                alertService: alertService,
                flatId: flatId,
                clientId: clientId,
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
            
        case let .serviceIsActivated(service, contractName, address):
            let vm = ServiceIsActivatedViewModel(
                router: weakRouter,
                service: service,
                issueService: issueService,
                contractName: contractName,
                address: address
            )
            
            let vc = ServiceIsActivatedViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .serviceIsNotActivated(service, contractName, address):
            let vm = ServiceIsNotActivatedViewModel(
                router: weakRouter,
                service: service,
                contractName: contractName,
                address: address,
                issueService: issueService
            )
            
            let vc = ServiceIsNotActivatedViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .serviceUnavailable(service, address, contractName):
            let vm = ServiceUnavailableViewModel(
                router: weakRouter,
                service: service,
                address: address,
                issueService: issueService,
                contractName: contractName
            )
            
            let vc = ServiceUnavailableViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case .advancedSettings:
            let vm = CommonSettingsViewModel(
                apiWrapper: apiWrapper,
                accessService: accessService,
                pushNotificationService: pushNotificationService,
                logoutHelper: logoutHelper,
                alertService: alertService,
                router: weakRouter
            )
            
            let vc = CommonSettingsViewController(viewModel: vm)
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
            
        case let .addressAccess(address, flatId, clientId):
            let vm = AddressAccessViewModel(
                router: weakRouter,
                address: address,
                flatId: flatId,
                clientId: clientId,
                apiWrapper: apiWrapper,
                permissionService: permissionService,
                logoutHelper: logoutHelper,
                alertService: alertService
            )
            
            let vc = AddressAccessViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .safariPage(url):
            let vc = SFSafariViewController(url: url)
            
            return .present(vc)
        
        case .editName:
            let vm = EditNameViewModel(
                accessService: accessService,
                apiWrapper: apiWrapper,
                logoutHelper: logoutHelper,
                alertService: alertService,
                router: weakRouter
            )
            
            let vc = EditNameViewController(viewModel: vm, preloadedName: accessService.clientName)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .facesSettings(flatId, address):
            let vm = FacesSettingsViewModel(
                apiWrapper: apiWrapper,
                accessService: accessService,
                alertService: alertService,
                router: weakRouter,
                flatId: flatId,
                address: address
            )
            
            let vc = FacesSettingsViewController(viewModel: vm)
            return .push(vc)
            
        case let .showFace(image):
            let vc = FaceViewController(image: image)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
        
        case let .deleteFace(image, flatId, faceId):
            let vc = DeleteFaceViewController(apiWrapper: apiWrapper, image: image, flatId: flatId, faceId: faceId)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
        
        case let .addFace(flatId, address):
            let coordinator = HistoryCoordinator(
                rootVC: rootViewController,
                apiWrapper: apiWrapper,
                pushNotificationService: pushNotificationService,
                accessService: accessService,
                issueService: issueService,
                permissionService: permissionService,
                alertService: alertService,
                logoutHelper: logoutHelper,
                flatId: flatId,
                eventsFilter: EventsFilter.keys,
                address: address
            )
            
            addChild(coordinator)
            return .none()
            
        case let .addFaceFromEvent(event):
            let vc = AddFaceViewController(apiWrapper: apiWrapper, event: event)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .showModal(content):
            let vc = ModalViewController(dismissCallback: { self.trigger(.dismiss) }, content: content)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .deleteFaceFromEvent(event, imageURL):
            let vc = DeleteFaceViewController(apiWrapper: apiWrapper, imageURL: imageURL, event: event)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve

            return .present(vc)

        }
    }
    
}
