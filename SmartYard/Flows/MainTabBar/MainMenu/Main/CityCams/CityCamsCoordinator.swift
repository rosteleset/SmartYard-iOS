//
//  CityCamsCoordinator.swift
//  SmartYard
//
//  Created by Александр Васильев on 14.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import XCoordinator
import RxSwift
import RxCocoa
import SafariServices

enum CityCamsRoute: Route {
    
    case main
    case alert(title: String, message: String?)
    case dialog(title: String, message: String?, actions: [UIAlertAction])
    case back
    case cameraContainer(selectedCamera: CityCameraObject)
    case requestRecord(selectedCamera: CityCameraObject)
    case safariPage(url: URL)
    case youTubeSafari(url: URL)
}

class CityCamsCoordinator: NavigationCoordinator<CityCamsRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let issueService: IssueService
    private let permissionService: PermissionService
    private let alertService: AlertService
    private let logoutHelper: LogoutHelper
    
    init(
        rootViewController: RootViewController,
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
        
        super.init(rootViewController: rootViewController, initialRoute: nil)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: CityCamsRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = CityMapViewModel(
                apiWrapper: apiWrapper,
                router: weakRouter
            )
            
            let vc = CityMapViewController(viewModel: vm)
            
            return .push(vc)
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case let .dialog(title, message, actions):
            return .dialogTransition(title: title, message: message, actions: actions)
            
        case .back:
            return .pop(animation: .default)
            
        case let .cameraContainer(selectedCamera):
            let vm = CityCameraViewModel(
                camera: selectedCamera,
                apiWrapper: apiWrapper,
                router: weakRouter
            )
            
            let vc = CityCameraViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .safariPage(url):
            let vc = SFSafariViewController(url: url)
            return .present(vc)
        
        case let .youTubeSafari(url):
            UIApplication.shared.open(url)
        return .none()
        
        case .requestRecord(selectedCamera: let selectedCamera):
            let vm = RequestRecordViewModel(
                camera: selectedCamera,
                issueService: issueService,
                router: weakRouter
            )
            
            let vc = RequestRecordViewController(viewModel: vm)
            
            return .push(vc)
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
