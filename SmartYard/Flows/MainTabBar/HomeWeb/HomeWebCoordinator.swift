//
//  PaymentsCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length cyclomatic_complexity

import XCoordinator
import SafariServices
import RxSwift
import RxCocoa

enum HomeWebRoute: Route {
    
    case main
    case appSettings(title: String, message: String?)
    case alert(title: String, message: String?)
    case dialog(title: String, message: String?, actions: [UIAlertAction])
    case back
    case share(items: [Any])
    case pdfView(url: URL)
    case dismiss
    case dismissAndOpen(url: URL)
    case safariPage(url: URL)
    case accessService(address: String, flatId: String, clientId: String?)
    case homeCameras(houseId: String, address: String)
    case historyEvents(houseId: String?, address: String)
    case fullscreen(camId: Int, houseId: String)
    case notifications
    case inputContract(isManualTrigger: Bool)
    case inputAddress
    case availableServices(address: String, services: [APIServiceModel])
    case unavailableServices(address: String)
    case confirmAddress(address: String)
    case restorePassword(contractNum: String?)
    case pinCode(contractNum: String, selectedRestoreMethod: RestoreMethod)
    case acceptOfferta(login: String, password: String, offers: [APIOffers])
    case acceptOffertaByAddress(houseId: String, flat: String?, offers: [APIOffers])

//    case webViewPopup(url: URL, backButtonLabel: String)
//    case webView(url: URL, backButtonLabel: String)
    
}

class HomeWebCoordinator: NavigationCoordinator<HomeWebRoute> {
    
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
        subscribeToNewInboxNotifications()
    }
    
    override func prepareTransition(for route: HomeWebRoute) -> NavigationTransition {
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
            
        case let .dismissAndOpen(url):
            trigger(.dismiss) { [weak self] in
                self?.trigger(.safariPage(url: url))
            }
            return .none()
    
        case let .appSettings(title, message):
            return .appSettingsTransition(title: title, message: message)
            
        case .main:
//            guard !self.apiWrapper.accessService.centraScreenUrl.isEmpty,
//                  let url = URL(string: self.apiWrapper.accessService.centraScreenUrl) else {
//                return .alertTransition(title: "Ошибка", message: "Не удаётся открыть главную страницу.")
//            }

            let vm = WebViewHomeModel(
                apiWrapper: apiWrapper,
                permissionService: permissionService,
                pushNotificationService: pushNotificationService,
                accessService: accessService,
                alertService: alertService,
                logoutHelper: logoutHelper,
                router: weakRouter
//                url: url
            )
            
            let vc = WebViewHomeController(
                viewModel: vm,
                accessToken: apiWrapper.accessService.accessToken ?? ""
            )
            let nc = rootViewController
            nc.popViewController(animated: false)

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
            
        case let .historyEvents(houseId, address):
            let houseId: Int? = {
                guard let houseId = houseId else {
                    return nil
                }
                return Int(houseId)
            }()
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
            
        case let .fullscreen(camId, houseId):
            let vm = FullscreenHomeViewModel(
                apiWrapper: apiWrapper,
                houseId: houseId,
                router: weakRouter
            )
            
            let vc = FullscreenHomePlayerViewController(
                apiWrapper: apiWrapper,
                viewModel: vm,
                camId: camId
            )
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve

            return .present(vc)
            
        case .notifications:
            let vm = NotificationsHomeViewModel(
                apiWrapper: apiWrapper,
                pushNotificationService: pushNotificationService,
                logoutHelper: logoutHelper,
                alertService: alertService,
                router: weakRouter
            )
            
            let vc = NotificationsHomeViewController(viewModel: vm)
            return .push(vc)
            
        case let .inputContract(isManualTrigger):
            let vm = AuthByContractNumViewModel(
                routerweb: weakRouter,
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
                
//                if (rootViewController.viewControllers.contains { $0 is AuthByContractNumViewController }) {
//                    return .none()
//                } else {
                    return .push(vc)
//                }
            }()
            return transition

        case .inputAddress:
            let vm = InputAddressViewModel(
                routerweb: weakRouter,
                apiWrapper: apiWrapper,
                permissionService: permissionService,
                logoutHelper: logoutHelper,
                alertService: alertService
            )
            
            let vc = InputAddressViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .availableServices(address, services):
            let vm = AvailableServicesViewModel(
                routerweb: weakRouter,
                apiWrapper: apiWrapper,
                issueService: issueService,
                address: address,
                services: services
            )
            
            let vc = AvailableServicesViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .unavailableServices(address):
            let vm = ServicesActivationRequestViewModel(
                routerweb: weakRouter,
                apiWrapper: apiWrapper,
                issueService: issueService,
                address: address
            )
            
            let vc = ServicesActivationRequestViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .confirmAddress(address):
            let vm = AddressConfirmationViewModel(
                routerweb: weakRouter,
                apiWrapper: apiWrapper,
                issueService: issueService,
                address: address
            )
            
            let vc = AddressConfirmationViewController(viewModel: vm)
            
            return .push(vc)
        
        case let .acceptOfferta(login, password, offers):
            let vm = AcceptOffertaByContractViewModel(
                routerweb: weakRouter,
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
                routerweb: weakRouter,
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
            
        case let .pinCode(contractNum, restoreMethod):
            let vm = PassConfirmationPinViewModel(
                apiWrapper: apiWrapper,
                logoutHelper: logoutHelper,
                alertService: alertService,
                routerweb: weakRouter,
                contractNum: contractNum,
                selectedRestoreMethod: restoreMethod
            )
            
            let vc = PassConfirmationPinViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .restorePassword(contractNum):
            let vm = RestorePasswordViewModel(
                apiWrapper: apiWrapper,
                logoutHelper: logoutHelper,
                alertService: alertService,
                routerweb: weakRouter
            )
            
            let vc = RestorePasswordViewController(viewModel: vm, preloadedContractNumber: contractNum)
            
            return .push(vc)
            
        case let .safariPage(url):
            let vc = SFSafariViewController(url: url)
            return .present(vc)
            
//        case let .webView(url, backButtonLabel):
//            let vm = WebViewHomeModel(
//                apiWrapper: apiWrapper,
//                router: weakRouter,
//                url: url
//            )
//            
//            let vc = WebViewHomeController(
//                viewModel: vm,
//                backButtonLabel: backButtonLabel,
//                accessToken: apiWrapper.accessService.accessToken ?? ""
//            )
//            return .push(vc)
//            
//        case let .webViewPopup(url, backButtonLabel):
//            let vm = WebViewHomeModel(
//                apiWrapper: apiWrapper,
//                router: weakRouter,
//                url: url
//            )
//            
//            let vc = WebPopupController(
//                viewModel: vm,
//                backButtonLabel: backButtonLabel,
//                accessToken: apiWrapper.accessService.accessToken ?? ""
//            )
//            vc.modalPresentationStyle = .overFullScreen
//            
//            return .present(vc)
        }
    }
    
    private func subscribeToNewInboxNotifications() {
        NotificationCenter.default.rx.notification(.updateInboxNotificationsSelect)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] notification in
                    guard let self = self else {
                        return
                    }
                    // MARK: Если в стеке уже есть NotificationsHomeViewController - ничего делать не надо
                    guard !(self.rootViewController.viewControllers.contains {
                        $0 is NotificationsHomeViewController
                    }) else {
                        return
                    }
                    // MARK: Если его нет в стеке - принудительно отправляем юзера на страницу уведомлений
                    print("goto notification")
                    self.trigger(.notifications)
                }
            )
            .disposed(by: disposeBag)
    }

}
// swiftlint:enable function_body_length cyclomatic_complexity
