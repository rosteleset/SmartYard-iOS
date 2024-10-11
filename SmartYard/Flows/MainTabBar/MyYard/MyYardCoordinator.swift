//
//  MyYardCoordinator.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 05.04.2024.
//  Copyright © 2024 Layka. All rights reserved.
//
// swiftlint:disable function_body_length cyclomatic_complexity

import XCoordinator
import SafariServices
import RxSwift
import RxCocoa
import SSCustomTabbar

enum MyYardRoute: Route {
    case main
    case appSettings(title: String, message: String?)
    case alert(title: String, message: String?)
    case dialog(title: String, message: String?, actions: [UIAlertAction])
    case back
    case share(items: [Any])
    case pdfView(url: URL)
    case dismiss
    case accessService(address: String, flatId: String, clientId: String?)
    case inputContract(isManualTrigger: Bool)
    case homeCameras(houseId: String, address: String)
    case homeCamera(houseId: String, camId: Int?)
    case fullscreen(houseId: String, camId: Int?)
    case cityCamera(camera: CityCameraObject)
    case inputAddress
    case restorePassword(contractNum: String?)
    case historyEvents(houseId: Int?, address: String)
    case availableServices(address: String, services: [APIServiceModel])
    case unavailableServices(address: String)
    case pinCode(contractNum: String, selectedRestoreMethod: RestoreMethod)
    case confirmAddress(address: String)
    case acceptOfferta(login: String, password: String, offers: [APIOffers])
    case acceptOffertaByAddress(houseId: String, flat: String?, offers: [APIOffers])
    case chatContact(chat: String, name: String?)
}

class MyYardCoordinator: NavigationCoordinator<MyYardRoute> {
    
    private let disposeBag = DisposeBag()
    
    let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let issueService: IssueService
    private let permissionService: PermissionService
    private let alertService: AlertService
    private let logoutHelper: LogoutHelper
    
    init(
        apiWrapper: APIWrapper,
        pushNotificationService: PushNotificationService,
        accessService: AccessService,
        issueService: IssueService,
        permissionService: PermissionService,
        alertService: AlertService,
        logoutHelper: LogoutHelper
    ) {
        self.apiWrapper = apiWrapper
        self.pushNotificationService = pushNotificationService
        self.accessService = accessService
        self.issueService = issueService
        self.permissionService = permissionService
        self.alertService = alertService
        self.logoutHelper = logoutHelper

        super.init(initialRoute: .main)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: MyYardRoute) -> NavigationTransition {
        switch route {
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case .back:
            return .pop(animation: .default)
            
        case let .dialog(title, message, actions):
            return .dialogTransition(title: title, message: message, actions: actions)
            
        case let .share(items):
            return .shareTransition(items: items)
            
        case .dismiss:
            return .dismiss(animation: .default)
            
        case let .appSettings(title, message):
            return .appSettingsTransition(title: title, message: message)
            
        case .main:
            let vm = MyYardViewModel(
                apiWrapper: apiWrapper,
                permissionService: permissionService,
                pushNotificationService: pushNotificationService,
                accessService: accessService,
                alertService: alertService,
                logoutHelper: logoutHelper,
                router: weakRouter
            )

            let vc = MyYardViewController(viewModel: vm, accessService: accessService)
            return .set([vc])
            
        case let .accessService(address, flatId, clientId):
            let coordinator = SettingsCoordinator(
                rootViewController: rootViewController,
                accessService: accessService,
                pushNotificationService: pushNotificationService,
                apiWrapper: apiWrapper,
                issueService: issueService,
                permissionService: permissionService,
                logoutHelper: logoutHelper,
                alertService: alertService,
                flatId: flatId,
                address: address,
                clientId: clientId
            )
            children.forEach { removeChild($0) }
            addChild(coordinator)
            return .none()
            
        case let .homeCameras(houseId, address):
            let coordinator = HomeCoordinator(
                rootVC: rootViewController,
                apiWrapper: apiWrapper,
                pushNotificationService: pushNotificationService,
                accessService: accessService,
                issueService: issueService,
                permissionService: permissionService,
                alertService: alertService,
                logoutHelper: logoutHelper,
                houseId: houseId,
                address: address
            )
            children.forEach { removeChild($0) }
            addChild(coordinator)
            return .none()
            
        case let .homeCamera(houseId, camId):
            let coordinator = HomeCoordinator(
                rootVC: rootViewController,
                apiWrapper: apiWrapper,
                pushNotificationService: pushNotificationService,
                accessService: accessService,
                issueService: issueService,
                permissionService: permissionService,
                alertService: alertService,
                logoutHelper: logoutHelper,
                houseId: houseId,
                camId: camId
            )
            children.forEach { removeChild($0) }
            addChild(coordinator)
            return .none()
            
        case let .fullscreen(houseId, camId):
            let coordinator = HomeCoordinator(
                rootVC: rootViewController,
                apiWrapper: apiWrapper,
                pushNotificationService: pushNotificationService,
                accessService: accessService,
                issueService: issueService,
                permissionService: permissionService,
                alertService: alertService,
                logoutHelper: logoutHelper,
                houseId: houseId,
                camId: camId,
                fullscreen: true
            )
            children.forEach { removeChild($0) }
            addChild(coordinator)
            return .none()
            
        case let .cityCamera(camera):
            let coordinator = CityCamsCoordinator(
                rootViewController: rootViewController,
                apiWrapper: apiWrapper,
                pushNotificationService: pushNotificationService,
                accessService: accessService,
                issueService: issueService,
                permissionService: permissionService,
                alertService: alertService,
                logoutHelper: logoutHelper,
                camera: camera
            )
            children.forEach { removeChild($0) }
            addChild(coordinator)
            return .none()

        case let .historyEvents(houseId, address):
            let coordinator = HistoryCoordinator(
                rootVC: rootViewController,
                apiWrapper: apiWrapper,
                pushNotificationService: pushNotificationService,
                accessService: accessService,
                issueService: issueService,
                permissionService: permissionService,
                alertService: alertService,
                logoutHelper: logoutHelper,
                houseId: houseId,
                address: address
            )
            children.forEach { removeChild($0) }
            addChild(coordinator)
            return .none()
            
        case let .chatContact(chat, name):
            let coordinator = ChatwootCoordinator(
                rootVC: rootViewController,
                apiWrapper: apiWrapper,
                accessService: accessService,
                pushNotificationService: pushNotificationService,
                logoutHelper: logoutHelper,
                alertService: alertService,
                chat: chat,
                name: name
            )
            children.forEach { removeChild($0) }
            addChild(coordinator)
            return .none()
            
        case let .inputContract(isManualTrigger):
            let vm = AuthByContractNumViewModel(
                router: weakRouter,
                issueService: issueService,
                apiWrapper: apiWrapper,
                logoutHelper: logoutHelper,
                alertService: alertService
            )
            
            let vc = AuthByContractNumViewController(viewModel: vm, isShowingManual: isManualTrigger)
            
            let transition: NavigationTransition = {
                guard isManualTrigger else {
                    return .set([vc], animation: .fade)
                }
                
                return .push(vc)
            }()
            return transition
            
        case .inputAddress:
            let vm = InputAddressViewModel(
                router: weakRouter,
                apiWrapper: apiWrapper,
                permissionService: permissionService,
                logoutHelper: logoutHelper,
                alertService: alertService
            )
            
            let vc = InputAddressViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .restorePassword(contractNum):
            let vm = RestorePasswordViewModel(
                apiWrapper: apiWrapper,
                logoutHelper: logoutHelper,
                alertService: alertService,
                router: weakRouter
            )
            
            let vc = RestorePasswordViewController(viewModel: vm, preloadedContractNumber: contractNum)
            
            return .push(vc)
            
        case let .availableServices(address, services):
            let vm = AvailableServicesViewModel(
                router: weakRouter,
                apiWrapper: apiWrapper,
                issueService: issueService,
                address: address,
                services: services
            )
            
            let vc = AvailableServicesViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .unavailableServices(address):
            let vm = ServicesActivationRequestViewModel(
                router: weakRouter,
                apiWrapper: apiWrapper,
                issueService: issueService,
                address: address
            )
            
            let vc = ServicesActivationRequestViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .pinCode(contractNum, restoreMethod):
            let vm = PassConfirmationPinViewModel(
                apiWrapper: apiWrapper,
                logoutHelper: logoutHelper,
                alertService: alertService,
                router: weakRouter,
                contractNum: contractNum,
                selectedRestoreMethod: restoreMethod
            )
            
            let vc = PassConfirmationPinViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .confirmAddress(address):
            let vm = AddressConfirmationViewModel(
                router: weakRouter,
                apiWrapper: apiWrapper,
                issueService: issueService,
                address: address
            )
            
            let vc = AddressConfirmationViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .acceptOfferta(login, password, offers):
            let vm = AcceptOffertaByContractViewModel(
                router: weakRouter,
                issueService: issueService,
                apiWrapper: apiWrapper,
                logoutHelper: logoutHelper,
                alertService: alertService,
                offers: offers
            )
            vm.updateLP(login: login, password: password)
            let vc = AcceptOffertaByContractViewController(viewModel: vm)
            return .push(vc)
            
        case let .acceptOffertaByAddress(houseId, flat, offers):
            let vm = AcceptOffertaByContractViewModel(
                router: weakRouter,
                issueService: issueService,
                apiWrapper: apiWrapper,
                logoutHelper: logoutHelper,
                alertService: alertService,
                offers: offers
            )
            vm.updateHF(houseId: houseId, flat: flat)
            let vc = AcceptOffertaByContractViewController(viewModel: vm)
            return .push(vc)
            
        case let .pdfView(url):
            let vc = PDFViewController(pdfUrl: url)
            return .present(vc)
        }
    }
}
// swiftlint:enable function_body_length cyclomatic_complexity
