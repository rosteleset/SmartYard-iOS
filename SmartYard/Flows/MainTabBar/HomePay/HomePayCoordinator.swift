//
//  HomePayCoordinator.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 30.05.2024.
//  Copyright © 2024 Layka. All rights reserved.
//
// swiftlint:disable function_body_length cyclomatic_complexity

import XCoordinator
import SafariServices
import RxSwift
import RxCocoa
import SSCustomTabbar

enum HomePayRoute: Route {
    case main
    case appSettings(title: String, message: String?)
    case alert(title: String, message: String?)
    case dialog(title: String, message: String?, actions: [UIAlertAction])
    case showModal(withContent: ModalContent)
    case back
    case share(items: [Any])
    case dismiss
    case notifications
    case accessService(address: String, flatId: String, clientId: String?)
    case inputContract(isManualTrigger: Bool)
    case inputAddress
    case restorePassword(contractNum: String?)
    case availableServices(address: String, services: [APIServiceModel])
    case unavailableServices(address: String)
    case pinCode(contractNum: String, selectedRestoreMethod: RestoreMethod)
    case confirmAddress(address: String)
    case acceptOfferta(login: String, password: String, offers: [APIOffers])
    case acceptOffertaByAddress(houseId: String, flat: String?, offers: [APIOffers])
    case sendDetails(range: DetailRange)
    case pdfView(url: URL)
    case paymentPopup(clientId: String, contract: String)
    case selectTypePopup(cards: [PayTypeObject], height: CGFloat, merchant: Merchant)
    case payStatusPopup(merchant: Merchant, orderId: String?, errorTitle: String?, errorMessage: String?)
    case payStatusAccept(merchant: Merchant, orderId: String?, errorTitle: String?, errorMessage: String?)
    case activateLimit(contract: ContractFaceObject)
}

class HomePayCoordinator: NavigationCoordinator<HomePayRoute> {
    
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
    
    override func prepareTransition(for route: HomePayRoute) -> NavigationTransition {
        switch route {
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case .back:
            return .pop(animation: .default)
            
        case let .dialog(title, message, actions):
            return .dialogTransition(title: title, message: message, actions: actions)
            
        case let .showModal(content):
            let vc = ModalViewController(dismissCallback: { self.trigger(.dismiss) }, content: content)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .share(items):
            return .shareTransition(items: items)
            
        case .dismiss:
            return .dismiss(animation: .default)
            
        case let .appSettings(title, message):
            return .appSettingsTransition(title: title, message: message)
            
        case .main:
            let vm = HomePayViewModel(
                apiWrapper: apiWrapper,
                permissionService: permissionService,
                pushNotificationService: pushNotificationService,
                accessService: accessService,
                alertService: alertService,
                logoutHelper: logoutHelper,
                router: weakRouter
            )
            let vc = HomePayViewController(
                viewModel: vm
            )
            return .set([vc])

        case .notifications:
            let vm = NotificationsHomeViewModel(
                apiWrapper: apiWrapper,
                pushNotificationService: pushNotificationService,
                logoutHelper: logoutHelper,
                alertService: alertService,
                routerhomepay: weakRouter
            )
            
            let vc = NotificationsHomeViewController(viewModel: vm)
            return .push(vc)
            
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
            
        case let .inputContract(isManualTrigger):
            let vm = AuthByContractNumViewModel(
                routerhomepay: weakRouter,
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
                routerhomepay: weakRouter,
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
                routerhomepay: weakRouter
            )
            
            let vc = RestorePasswordViewController(viewModel: vm, preloadedContractNumber: contractNum)
            
            return .push(vc)
            
        case let .availableServices(address, services):
            let vm = AvailableServicesViewModel(
                routerhomepay: weakRouter,
                apiWrapper: apiWrapper,
                issueService: issueService,
                address: address,
                services: services
            )
            
            let vc = AvailableServicesViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .unavailableServices(address):
            let vm = ServicesActivationRequestViewModel(
                routerhomepay: weakRouter,
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
                routerhomepay: weakRouter,
                contractNum: contractNum,
                selectedRestoreMethod: restoreMethod
            )
            
            let vc = PassConfirmationPinViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .confirmAddress(address):
            let vm = AddressConfirmationViewModel(
                routerhomepay: weakRouter,
                apiWrapper: apiWrapper,
                issueService: issueService,
                address: address
            )
            
            let vc = AddressConfirmationViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .acceptOfferta(login, password, offers):
            let vm = AcceptOffertaByContractViewModel(
                routerhomepay: weakRouter,
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
                routerhomepay: weakRouter,
                issueService: issueService,
                apiWrapper: apiWrapper,
                logoutHelper: logoutHelper,
                alertService: alertService,
                offers: offers
            )
            vm.updateHF(houseId: houseId, flat: flat)
            let vc = AcceptOffertaByContractViewController(viewModel: vm)
            return .push(vc)
            
        case let .sendDetails(range):
            let vm = SendDetailsViewModel(
                accessService: accessService,
                apiWrapper: apiWrapper,
                logoutHelper: logoutHelper,
                alertService: alertService,
                router: weakRouter
            )
            
            let vc = SendDetailsViewController(viewModel: vm, range: range)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .activateLimit(contract):
            let vm = ActivateLimitViewModel(
                accessService: accessService,
                apiWrapper: apiWrapper,
                contract: contract,
                router: weakRouter
            )
            
            let vc = ActivateLimitViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .paymentPopup(clientId, contract):
            let vm = PayPopupViewModel(
                accessService: accessService,
                apiWrapper: apiWrapper,
                clientId: clientId,
                contractNumber: contract,
                router: weakRouter
            )
            
            let vc = PayPopupViewController(viewModel: vm)
            
            vc.modalPresentationStyle = .overFullScreen
            
            return .present(vc)
            
        case let .selectTypePopup(cards, height, merchant):
            let vm = PayTypeSelectViewModel(
                apiWrapper: apiWrapper,
                cards: cards,
                merchant: merchant,
                router: weakRouter
            )
            
            let vc = PayTypeSelectViewController(viewModel: vm, height: height)
            
            vc.modalPresentationStyle = .overFullScreen
            
            return .present(vc)
            
        case let .payStatusPopup(merchant, orderId, errorTitle, errorMessage):
            trigger(.dismiss) { [weak self] in
                self?.trigger(.payStatusAccept(merchant: merchant, orderId: orderId, errorTitle: errorTitle, errorMessage: errorMessage))
            }
            return .none()
            
        case let .payStatusAccept(merchant, orderId, errorTitle, errorMessage):
            let vm = PayStatusPopupViewModel(
                accessService: accessService,
                apiWrapper: apiWrapper,
                merchant: merchant,
                orderId: orderId,
                errorTitle: errorTitle,
                errorMessage: errorMessage,
                router: weakRouter
            )
            
            let vc = PayStatusPopupViewController(viewModel: vm)
            
            vc.modalPresentationStyle = .overFullScreen
            
            return .present(vc)
            
        case let .pdfView(url):
            let vc = PDFViewController(pdfUrl: url)
            return .present(vc)
            
        }
    }
}
// swiftlint:enable function_body_length cyclomatic_complexity
