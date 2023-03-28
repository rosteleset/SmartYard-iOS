//
//  ChatwootCoordinator.swift
//  SmartYard
//
//  Created by devcentra on 20.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

enum ChatwootRoute: Route {
    case main
    case premain
    case back
}

class ChatwootCoordinator: NavigationCoordinator<ChatwootRoute> {

    private let disposeBag = DisposeBag()
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService

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
        
        super.init(initialRoute: .premain)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
    }

    override func prepareTransition(for route: ChatwootRoute) -> NavigationTransition {
        switch route {
        case .premain:
            let vm = ChatwootPreviewModel(
                router: weakRouter
            )
            let vc = ChatwootPreviewController(viewModel: vm)
            return .set([vc])
        case .main:
            let vm = ChatwootViewModel(
                apiWrapper: apiWrapper,
                accessService: accessService,
                pushNotificationService: pushNotificationService,
                logoutHelper: logoutHelper,
                alertService: alertService,
                router: weakRouter
            )
            
            let vc = ChatwootViewController(viewModel: vm)
            
            // MARK: Загружаю сразу, чтобы иметь возможность нормально отправлять сообщения с "тарелочек"
            // Когда мы жмем на услугу, происходит отправка уведомления в Notification Center
            // Оно перебрасывает нас во вкладку "Чат", а затем vm пытается отправить сообщение
            // Вот только view в этот момент еще может быть не загружена, а transform - не вызван
            // Поэтому проще сразу ее загрузить, чем разруливать сложности
            
            vc.loadViewIfNeeded()
            
            return .set([vc])
        case .back:
            print("DEBUG - back")
            return .pop(animation: .default)
        }
    }

}
