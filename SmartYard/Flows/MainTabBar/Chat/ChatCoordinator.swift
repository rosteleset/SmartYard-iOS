//
//  ChatCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

enum ChatRoute: Route {
    case main
    case webView(url: URL)
    case alert(title: String, message: String)
}

class ChatCoordinator: NavigationCoordinator<ChatRoute> {
    
    private let disposeBag = DisposeBag()
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    var childCoordinator: WebViewCoordinator?
    
    
    init(
        apiWrapper: APIWrapper,
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        logoutHelper: LogoutHelper,
        alertService: AlertService
    ) {
        self.apiWrapper = apiWrapper
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        
        if self.apiWrapper.accessService.chatUrl.isEmpty {
            super.init(initialRoute: .main)
        } else {
            if let url = URL(string: self.apiWrapper.accessService.chatUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)) {
                super.init(initialRoute: .webView(url: url))
            } else {
                super.init(initialRoute: .alert(
                    title: NSLocalizedString("Error", comment: ""),
                    message: NSLocalizedString("Unable to open chat page.", comment: "")
                ))
            }
        }
        
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: ChatRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = ChatViewModel(
                apiWrapper: apiWrapper,
                accessService: accessService,
                pushNotificationService: pushNotificationService,
                logoutHelper: logoutHelper,
                alertService: alertService
            )
            
            let vc = ChatViewController(viewModel: vm)
            
            // MARK: Загружаю сразу, чтобы иметь возможность нормально отправлять сообщения с "тарелочек"
            // Когда мы жмем на услугу, происходит отправка уведомления в Notification Center
            // Оно перебрасывает нас во вкладку "Чат", а затем vm пытается отправить сообщение
            // Вот только view в этот момент еще может быть не загружена, а transform - не вызван
            // Поэтому проще сразу ее загрузить, чем разруливать сложности
            
            vc.loadViewIfNeeded()
            
            return .set([vc])
            
        case let .webView(url):
            childCoordinator = WebViewCoordinator(
                rootVC: rootViewController,
                apiWrapper: apiWrapper,
                url: url,
                backButtonLabel: "",
                push: false,
                version: 2
            )
            guard let childCoordinator = childCoordinator else {
                return .none()
            }
            children.forEach { removeChild($0) }
            addChild(childCoordinator)
            return .none()
            
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
        }
    }
    
}
