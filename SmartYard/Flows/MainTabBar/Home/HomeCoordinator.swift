//
//  HomeCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import XCoordinator
import RxSwift
import RxCocoa

enum HomeRoute: Route {
    
    case main
    case alert(title: String, message: String?)
    case dialog(title: String, message: String?, actions: [UIAlertAction])
    case share(items: [Any])
    case appSettings(title: String, message: String?)
    case inputContract(isManualTrigger: Bool)
    case inputAddress
    case availableServices(address: String, services: [APIServiceModel])
    case unavailableServices(address: String)
    case confirmAddress(address: String)
    case back
    case dismiss
    case restorePassword(contractNum: String?)
    case pinCode(contractNum: String, selectedRestoreMethod: RestoreMethod)
    case qrCodeScan(delegate: QRCodeScanViewModelDelegate)
    case serviceSoonAvailable(issue: APIIssueConnect)
    case cameraContainer(address: String, cameras: [CameraObject], selectedCamera: CameraObject)
    case yardCamerasMap(houseId: String, address: String, cameras: [CameraObject]?)
    case yardCamerasList(houseId: String, address: String, tree: CamerasTree, path: [Int])
    case playArchiveVideo(camera: CameraObject, date: Date, availableRanges: [APIArchiveRange])
    case history(houseId: String, address: String)
}

final class HomeCoordinator: NavigationCoordinator<HomeRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let apiWrapper: APIWrapper
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
        
        subscribeToNewAddressNotifications()
    }
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    override func prepareTransition(for route: HomeRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = AddressesListViewModel(
                apiWrapper: apiWrapper,
                permissionService: permissionService,
                pushNotificationService: pushNotificationService,
                accessService: accessService,
                alertService: alertService,
                logoutHelper: logoutHelper,
                router: weakRouter
            )
            
            let vc = AddressesListViewController(viewModel: vm)
            return .set([vc])
            
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case let .dialog(title, message, actions):
            return .dialogTransition(title: title, message: message, actions: actions)
            
        case let .share(items):
            return .shareTransition(items: items)

        case let .appSettings(title, message):
            return .appSettingsTransition(title: title, message: message)
            
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
                
                if (rootViewController.viewControllers.contains { $0 is AuthByContractNumViewController }) {
                    return .none()
                } else {
                    return .push(vc)
                }
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
            
        case let .confirmAddress(address):
            let vm = AddressConfirmationViewModel(
                router: weakRouter,
                apiWrapper: apiWrapper,
                issueService: issueService,
                address: address
            )
            
            let vc = AddressConfirmationViewController(viewModel: vm)
            
            return .push(vc)
        
        case .back:
            return .pop(animation: .default)
            
        case .dismiss:
            return .dismiss()
            
        case let .restorePassword(contractNum):
            let vm = RestorePasswordViewModel(
                apiWrapper: apiWrapper,
                logoutHelper: logoutHelper,
                alertService: alertService,
                router: weakRouter
            )
            
            let vc = RestorePasswordViewController(viewModel: vm, preloadedContractNumber: contractNum)
            
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
            
        case let .qrCodeScan(delegate):
            let vm = QRCodeScanViewModel(router: weakRouter, delegate: delegate)
            
            let vc = QRCodeScanViewController(viewModel: vm)
            vc.hidesBottomBarWhenPushed = true
            
            return .push(vc)
            
        case let .serviceSoonAvailable(issue):
            let vm = ServiceSoonAvailableViewModel(
                router: weakRouter,
                apiWrapper: apiWrapper,
                issueService: issueService,
                permissionService: permissionService,
                logoutHelper: logoutHelper,
                alertService: alertService,
                issue: issue
            )
            
            let vc = ServiceSoonAvailableViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .yardCamerasMap(houseId, address, cameras):
            let vm = YardMapViewModel(
                apiWrapper: apiWrapper,
                houseId: houseId,
                address: address,
                router: weakRouter,
                cameras: cameras
            )
            let vc = YardMapViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .yardCamerasList(houseId, address, tree, path):
            let vm = CamerasListViewModel(
                apiWrapper: apiWrapper,
                accessService: accessService,
                router: weakRouter,
                houseId: houseId,
                address: address,
                tree: tree,
                path: path
            )
            let vc = CamerasListViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .cameraContainer(address, cameras, selectedCamera):
            let vm = SelectCameraContainerViewModel(
                apiWrapper: apiWrapper,
                address: address,
                cameras: cameras,
                selectedCamera: selectedCamera,
                router: weakRouter
            )
            
            let onlineVc = OnlinePageViewController()
            onlineVc.loadViewIfNeeded()
            
            let archiveVc = ArchivePageViewController(apiWrapper: apiWrapper)
            archiveVc.loadViewIfNeeded()
            
            let vc = SelectCameraContainerViewController(
                onlinePage: onlineVc,
                archivePage: archiveVc,
                viewModel: vm
            )
            
            return .push(vc)
            
        case let .playArchiveVideo(camera, date, availableRanges):
            let vm = PlayArchiveVideoViewModel(
                apiWrapper: apiWrapper,
                camera: camera,
                date: date,
                availableRanges: availableRanges,
                router: weakRouter
            )
            
            let vc = PlayArchiveVideoViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .history(houseId, address):
            
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
            
            addChild(coordinator)
            return .none()
        }
    }
    
    private func subscribeToNewAddressNotifications() {
        NotificationCenter.default.rx.notification(.addressAdded)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    // MARK: Если в стеке уже есть AddressesListViewController - ничего делать не надо
                    guard !(self.rootViewController.viewControllers.contains {
                        $0 is AddressesListViewController
                    }) else {
                        return
                    }
                    
                    // MARK: Если его нет в стеке - принудительно возвращаем юзера на главный экран
                    self.trigger(.main)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
