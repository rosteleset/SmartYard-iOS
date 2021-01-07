//
//  PaymentsCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 LanTa. All rights reserved.
//

import XCoordinator
import SafariServices
import RxSwift
import RxCocoa

enum MainMenuRoute: Route {
    
    case main
    case settings
    case alert(title: String, message: String)
    case back
    case safariPage(url: URL)
}

class MainMenuCoordinator: NavigationCoordinator<MainMenuRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    private let permissionService: PermissionService
    private let alertService: AlertService
    private let logoutHelper: LogoutHelper
    
    private var settingsRouter: StrongRouter<SettingsRoute>!
    
    
    init(
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
        self.alertService = alertService
        self.logoutHelper = logoutHelper
        
        super.init(initialRoute: .main)
        // MARK: Settings View
        let settingsCoordinator = SettingsCoordinator(
            rootViewController: rootViewController,
            accessService: accessService,
            pushNotificationService: pushNotificationService,
            apiWrapper: apiWrapper,
            issueService: issueService,
            permissionService: permissionService,
            logoutHelper: logoutHelper,
            alertService: alertService
        )
        
        self.settingsRouter = settingsCoordinator.strongRouter
        
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: MainMenuRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = MainMenuViewModel(apiWrapper: apiWrapper, router: weakRouter)
            let vc = MainMenuViewController(viewModel: vm)
            return .set([vc])
            
        case .settings:
            return .trigger(SettingsRoute.main, on: settingsRouter)
            
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case .back:
            return .pop(animation: .default)
            
        case let .safariPage(url):
            let vc = SFSafariViewController(url: url)
            return .present(vc)
        }
    }
}
