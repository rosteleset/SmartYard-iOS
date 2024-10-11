//
//  PaymentsCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length cyclomatic_complexity type_body_length

import XCoordinator
import SafariServices
import RxSwift
import RxCocoa
import SSCustomTabbar

enum IntercomWebRoute: Route {
    
    case main
    case appSettings(title: String, message: String?)
    case alert(title: String, message: String?)
    case dialog(title: String, message: String?, actions: [UIAlertAction])
    case back
    case share(items: [Any])
//    case pdfView(url: URL)
    case dismiss
    case dismissAndOpen(url: URL)
    case safariPage(url: URL)
    case accessService(address: String, flatId: String, clientId: String?)
//    case inputContract(isManualTrigger: Bool)
    case homeCameras(houseId: String, address: String)
    case homeCamera(houseId: String, camId: Int?)
    case fullscreen(camId: Int, houseId: String)
    case fullscreenarchive(camId: Int)
    case notifications
//    case inputAddress
//    case restorePassword(contractNum: String?)
    case historyEvents(houseId: String?, address: String)
//    case availableServices(address: String, services: [APIServiceModel])
//    case unavailableServices(address: String)
//    case pinCode(contractNum: String, selectedRestoreMethod: RestoreMethod)
//    case confirmAddress(address: String)
    case archivedownload(vm: FullscreenArchiveIntercomPlayerViewModel)
    case closeFullscreenArchive
    case closeArchiveDownload
//    case acceptOfferta(login: String, password: String, offers: [APIOffers])
//    case acceptOffertaByAddress(houseId: String, flat: String?, offers: [APIOffers])

}

class IntercomWebCoordinator: NavigationCoordinator<IntercomWebRoute> {
    
    private let disposeBag = DisposeBag()
    
    let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let issueService: IssueService
    private let permissionService: PermissionService
    private let alertService: AlertService
    private let logoutHelper: LogoutHelper
    
    private var fullscreenBlackBackWindow: UIWindow?
    private var fullscreenBlackBack: BlackBackController?
    private var fullscreenArchiveWindow: UIWindow?
    private var fullscreenArchiveLandscapeVC: FullscreenArchiveIntercomLandscapeViewController?
    private var fullscreenArchivePortraitVC: FullscreenArchiveIntercomPlayerViewController?
    private var temporarilyIgnoredOrientation: UIDeviceOrientation?
    private var fullscreenArchiveDownloadWindow: UIWindow?
    private var fullscreenArchiveDownloadVC: FullscreenArchiveIntercomClipViewController?

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
        
        observeOrientationChanges()
    }
    
    override func prepareTransition(for route: IntercomWebRoute) -> NavigationTransition {
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
            let vm = WebViewIntercomModel(
                apiWrapper: apiWrapper,
                permissionService: permissionService,
                pushNotificationService: pushNotificationService,
                accessService: accessService,
                alertService: alertService,
                logoutHelper: logoutHelper,
                router: weakRouter
            )

            let vc = WebViewIntercomController(
                viewModel: vm,
                accessToken: apiWrapper.accessService.accessToken ?? ""
            )
            let nc = rootViewController
            nc.popViewController(animated: false)

            return .push(vc)

        case .notifications:
            let vm = NotificationsHomeViewModel(
                apiWrapper: apiWrapper,
                pushNotificationService: pushNotificationService,
                logoutHelper: logoutHelper,
                alertService: alertService,
                routerintercom: weakRouter
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
            let vm = FullscreenIntercomViewModel(
                apiWrapper: apiWrapper,
                houseId: houseId,
                camId: camId,
                router: weakRouter
            )

            let vc = FullscreenIntercomPlayerViewController(
                apiWrapper: apiWrapper,
                viewModel: vm,
                camId: camId
            )
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve

            return .present(vc)
            
        case let .fullscreenarchive(camId):
            let vm = FullscreenArchiveIntercomPlayerViewModel(
                apiWrapper: apiWrapper,
                camId: camId,
                router: weakRouter
            )

            let portraitVC = FullscreenArchiveIntercomPlayerViewController(
                viewModel: vm
            )
            portraitVC.modalPresentationStyle = .overFullScreen
            portraitVC.modalTransitionStyle = .crossDissolve
            portraitVC.loadViewIfNeeded()

            self.fullscreenArchivePortraitVC = portraitVC
            
            let landscapeVC = FullscreenArchiveIntercomLandscapeViewController(
                viewModel: vm
            )
            landscapeVC.modalPresentationStyle = .overFullScreen
            landscapeVC.modalTransitionStyle = .crossDissolve
            landscapeVC.loadViewIfNeeded()
            
            self.fullscreenArchiveLandscapeVC = landscapeVC
            
            let blackBackVC = BlackBackController()
            fullscreenBlackBackWindow = UIWindow()
            fullscreenBlackBackWindow?.rootViewController = blackBackVC
            fullscreenBlackBackWindow?.makeKeyAndVisible()
            
            fullscreenArchiveWindow = UIWindow()
            
            if [.landscapeLeft, .landscapeRight].contains(UIDevice.current.orientation) {
                fullscreenArchiveWindow?.rootViewController = landscapeVC
            } else {
                fullscreenArchiveWindow?.rootViewController = portraitVC
            }
            fullscreenArchiveWindow?.makeKeyAndVisible()

            return .none()
            
        case .closeFullscreenArchive:
            if let portraitVC = fullscreenArchivePortraitVC {
                fullscreenArchiveWindow?.switchRootViewController(to: portraitVC)
            }
            fullscreenBlackBackWindow = nil
            fullscreenBlackBack = nil
            fullscreenArchiveWindow = nil
            fullscreenArchivePortraitVC = nil
            fullscreenArchiveLandscapeVC = nil
            temporarilyIgnoredOrientation = nil
            
//            DispatchQueue.main.async { [weak self] in
//                self?.mainWindow.makeKeyAndVisible()
//            }
            
            return .none()
            
        case let .archivedownload(vm):
            let vc = FullscreenArchiveIntercomClipViewController(
                viewmodel: vm
            )
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            self.fullscreenArchiveDownloadVC = vc
            
            fullscreenArchiveDownloadWindow = UIWindow()
            fullscreenArchiveDownloadWindow?.rootViewController = vc
            fullscreenArchiveDownloadWindow?.makeKeyAndVisible()

            return .none()

        case .closeArchiveDownload:
            
            fullscreenArchiveDownloadWindow = nil
            fullscreenArchiveDownloadVC = nil
            
            return .none()
            
//        case let .inputContract(isManualTrigger):
//            let vm = AuthByContractNumViewModel(
//                routerintercom: weakRouter,
//                issueService: issueService,
//                apiWrapper: apiWrapper,
//                logoutHelper: logoutHelper,
//                alertService: alertService
//            )
//            
//            let vc = AuthByContractNumViewController(viewModel: vm, isShowingManual: isManualTrigger)
//            
//            let transition: NavigationTransition = {
//                guard isManualTrigger else {
//                    return .set([vc], animation: .fade)
//                }
                
////                if (rootViewController.viewControllers.contains { $0 is AuthByContractNumViewController }) {
////                    print("AuthByContractNumViewController already contained in root")
////                    return .none()
////                } else {
////                    print("AuthByContractNumViewController not exist in root")
//                    return .push(vc)
////                }
//            }()
//            return transition

//        case .inputAddress:
//            let vm = InputAddressViewModel(
//                routerintercom: weakRouter,
//                apiWrapper: apiWrapper,
//                permissionService: permissionService,
//                logoutHelper: logoutHelper,
//                alertService: alertService
//            )
//            
//            let vc = InputAddressViewController(viewModel: vm)
//            
//            return .push(vc)
//            
//        case let .restorePassword(contractNum):
//            let vm = RestorePasswordViewModel(
//                apiWrapper: apiWrapper,
//                logoutHelper: logoutHelper,
//                alertService: alertService,
//                routerintercom: weakRouter
//            )
//            
//            let vc = RestorePasswordViewController(viewModel: vm, preloadedContractNumber: contractNum)
//            
//            return .push(vc)
//            
//        case let .availableServices(address, services):
//            let vm = AvailableServicesViewModel(
//                routerintercom: weakRouter,
//                apiWrapper: apiWrapper,
//                issueService: issueService,
//                address: address,
//                services: services
//            )
//            
//            let vc = AvailableServicesViewController(viewModel: vm)
//            
//            return .push(vc)
            
//        case let .unavailableServices(address):
//            let vm = ServicesActivationRequestViewModel(
//                routerintercom: weakRouter,
//                apiWrapper: apiWrapper,
//                issueService: issueService,
//                address: address
//            )
//            
//            let vc = ServicesActivationRequestViewController(viewModel: vm)
//            
//            return .push(vc)
            
//        case let .pinCode(contractNum, restoreMethod):
//            let vm = PassConfirmationPinViewModel(
//                apiWrapper: apiWrapper,
//                logoutHelper: logoutHelper,
//                alertService: alertService,
//                routerintercom: weakRouter,
//                contractNum: contractNum,
//                selectedRestoreMethod: restoreMethod
//            )
//            
//            let vc = PassConfirmationPinViewController(viewModel: vm)
//            
//            return .push(vc)
            
//        case let .confirmAddress(address):
//            let vm = AddressConfirmationViewModel(
//                routerintercom: weakRouter,
//                apiWrapper: apiWrapper,
//                issueService: issueService,
//                address: address
//            )
//            
//            let vc = AddressConfirmationViewController(viewModel: vm)
//            
//            return .push(vc)
//            
//        case let .acceptOfferta(login, password, offers):
//            let vm = AcceptOffertaByContractViewModel(
//                routerintercom: weakRouter,
//                issueService: issueService,
//                apiWrapper: apiWrapper,
//                logoutHelper: logoutHelper,
//                alertService: alertService,
//                offers: offers
//            )
//            vm.updateLP(login: login, password: password)
//            let vc = AcceptOffertaByContractViewController(viewModel: vm)
//            return .push(vc)
//            
//        case let .acceptOffertaByAddress(houseId, flat, offers):
//            let vm = AcceptOffertaByContractViewModel(
//                routerintercom: weakRouter,
//                issueService: issueService,
//                apiWrapper: apiWrapper,
//                logoutHelper: logoutHelper,
//                alertService: alertService,
//                offers: offers
//            )
//            vm.updateHF(houseId: houseId, flat: flat)
//            let vc = AcceptOffertaByContractViewController(viewModel: vm)
//            return .push(vc)
//            
//        case let .pdfView(url):
//            let vc = PDFViewController(pdfUrl: url)
//            return .present(vc)
            
        case let .safariPage(url):
            let vc = SFSafariViewController(url: url)
            return .present(vc)
            
        }
    }
    
    private func observeOrientationChanges() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        NotificationCenter.default.rx
            .notification(UIDevice.orientationDidChangeNotification)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self,
                        UIDevice.current.orientation != self.temporarilyIgnoredOrientation,
                        let fullscrennArchiveWindow = self.fullscreenArchiveWindow,
                        let landscapeVC = self.fullscreenArchiveLandscapeVC,
                        let portraitVC = self.fullscreenArchivePortraitVC else {
                        return
                    }
                    
                    self.temporarilyIgnoredOrientation = nil
                    
                    let option: UIView.AnimationOptions = [.transitionCrossDissolve, .layoutSubviews]
                    let duration: TimeInterval = 0.8
                    
                    if UIDevice.current.orientation == .portrait,
                        fullscrennArchiveWindow.rootViewController === landscapeVC {
                        fullscrennArchiveWindow.switchRootViewController(to: portraitVC, animated: true, duration: duration, options: option)
                        // Этот костыль нужен, т.к. StackView и player не отрабатывают старые значения
                        // constraints. Возможно есть другое решение ((
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            portraitVC.viewDidLayoutSubviews()
                        }
                        return
                    }
                    
                    if [.landscapeLeft, .landscapeRight].contains(UIDevice.current.orientation),
                        fullscrennArchiveWindow.rootViewController === portraitVC {
                        fullscrennArchiveWindow.switchRootViewController(to: landscapeVC, animated: true, duration: duration, options: option)
                        return
                    }
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.fullscreenArchiveForceLandscape)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self,
                        let fullscreenArchiveWindow = self.fullscreenArchiveWindow,
                        let landscapeVC = self.fullscreenArchiveLandscapeVC else {
                        return
                    }
                    
                    self.temporarilyIgnoredOrientation = UIDevice.current.orientation
                    
                    let option: UIView.AnimationOptions = [.transitionCrossDissolve, .layoutSubviews]
                    let duration: TimeInterval = 0.8
                    
                    fullscreenArchiveWindow.switchRootViewController(to: landscapeVC, animated: true, duration: duration, options: option)
                }
            )
            .disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(.fullscreenArchiveForcePortrait)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self,
                        let fullscreenArchiveWindow = self.fullscreenArchiveWindow,
                        let portraitVC = self.fullscreenArchivePortraitVC else {
                        return
                    }
                    
                    self.temporarilyIgnoredOrientation = UIDevice.current.orientation
                    
                    let option: UIView.AnimationOptions = [.transitionCrossDissolve, .layoutSubviews]
                    let duration: TimeInterval = 0.8
                    
                    fullscreenArchiveWindow.switchRootViewController(to: portraitVC, animated: true, duration: duration, options: option)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        portraitVC.viewDidLayoutSubviews()
                    }
                }
            )
            .disposed(by: disposeBag)
    }
}
// swiftlint:enable function_body_length cyclomatic_complexity type_body_length
