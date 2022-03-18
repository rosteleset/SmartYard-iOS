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
    case cityCams
    case settings
    case profile
    case callSupport
    case alert(title: String, message: String)
    case back
    case webView(url: URL)
    case webViewFromContent(content: String, baseURL: String)
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
    private var cityCamsRouter: StrongRouter<CityCamsRoute>!
    
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
        
        let cityCamsCoordinator = CityCamsCoordinator(
            rootViewController: rootViewController,
            apiWrapper: apiWrapper,
            pushNotificationService: pushNotificationService,
            accessService: accessService,
            issueService: issueService,
            permissionService: permissionService,
            alertService: alertService,
            logoutHelper: logoutHelper
        )
        
        self.settingsRouter = settingsCoordinator.strongRouter
        self.cityCamsRouter = cityCamsCoordinator.strongRouter
        
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    // swiftlint:disable:next function_body_length
    override func prepareTransition(for route: MainMenuRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = MainMenuViewModel(apiWrapper: apiWrapper, router: weakRouter)
            let vc = MainMenuViewController(viewModel: vm)
            return .set([vc])
        
        case .cityCams:
            return .trigger(CityCamsRoute.main, on: cityCamsRouter)
            
        case .settings:
            return .trigger(SettingsRoute.main, on: settingsRouter)
        
        case .profile:
            return .trigger(SettingsRoute.advancedSettings, on: settingsRouter)
            
        case .callSupport:
            
            let callHandler = { (_: UIAlertAction) -> Void in
               if let phoneCallURL = URL(string: "tel://+7(4752)429999") {
                    let application = UIApplication.shared
                    if application.canOpenURL(phoneCallURL) {
                        application.open(phoneCallURL, options: [:], completionHandler: nil)
                    }
                  }
            }
            
            let activityTracker = ActivityTracker()
            let errorTracker = ErrorTracker()
            
            errorTracker.asDriver()
                .drive(
                    onNext: { [weak self] error in
                        self?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    }
                )
                .disposed(by: self.disposeBag)
            
            let callbackHandler = { [weak self] (_: UIAlertAction) -> Void in
                guard let self = self else {
                    return
                }
                    self.issueService
                        .sendCallbackIssue()
                        .trackError(errorTracker)
                        .trackActivity(activityTracker)
                        .asDriver(onErrorJustReturn: nil)
                        .drive(
                            onNext: { response in
                                guard response != nil else {
                                    return
                                }
                                self.trigger(
                                    .alert(
                                        title: "Заявка отправлена",
                                        message: "Мы позвоним Вам в ближайшее время"
                                    )
                                )
                            }
                        )
                        .disposed(by: self.disposeBag)
            }
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Заказать обратный звонок", style: .default, handler: callbackHandler))
            alert.addAction(UIAlertAction(title: "Позвонить по телефону", style: .default, handler: callHandler))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
            
            self.viewController.present(alert, animated: true, completion: nil)
            return.none()
            
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case .back:
            return .pop(animation: .default)
            
        case let .webView(url):
            let coordinator = WebViewCoordinator(
                rootVC: rootViewController,
                apiWrapper: apiWrapper,
                url: url,
                backButtonLabel: "Меню",
                push: true
            )
            
            addChild(coordinator)
            return .none()
            
        case let .webViewFromContent(content, baseURL):
            let coordinator = WebViewCoordinator(
                rootVC: rootViewController,
                apiWrapper: apiWrapper,
                content: content,
                baseURL: baseURL,
                backButtonLabel: "Меню",
                push: true
            )
            
            addChild(coordinator)
            return .none()
        }
    }
}
