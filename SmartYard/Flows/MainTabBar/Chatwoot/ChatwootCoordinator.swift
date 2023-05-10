//
//  ChatwootCoordinator.swift
//  SmartYard
//
//  Created by devcentra on 20.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import RxSwift
import RxCocoa
import XCoordinator

enum ChatwootRoute: Route {
    case main
    case personalchat(index: Int, items: [APIChat])
    case chatselect(chat: String)
    case back
    case alert(title: String, message: String?)
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
        
        super.init(initialRoute: .main)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
        
        subscribeToNewChatwootNotifications()
    }

    override func prepareTransition(for route: ChatwootRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = ChatwootSelectChatModel(
                apiWrapper: apiWrapper,
                accessService: accessService,
                logoutHelper: logoutHelper,
                alertService: alertService,
                router: weakRouter
            )
            let vc = ChatwootSelectChatController(viewModel: vm)
            return .set([vc])
        case let .chatselect(chat):
            let vm = ChatwootViewModel(
                apiWrapper: apiWrapper,
                accessService: accessService,
                pushNotificationService: pushNotificationService,
                logoutHelper: logoutHelper,
                alertService: alertService,
                chatRow: chat,
                router: weakRouter
            )
            let vc = ChatwootViewController(viewModel: vm)
            vc.loadViewIfNeeded()
            return .push(vc)
        case let .personalchat(index, items):
            let vm = ChatwootViewModel(
                apiWrapper: apiWrapper,
                accessService: accessService,
                pushNotificationService: pushNotificationService,
                logoutHelper: logoutHelper,
                alertService: alertService,
                chatRow: items[index].chat,
                router: weakRouter
            )
            
            if let typeChat = items[index].type,
               typeChat == "personal" {
                let vc = ChatwootViewController(viewModel: vm)

                vc.loadViewIfNeeded()
                return .push(vc)
            }
            
            return .alertTransition(title: "Чат недоступен", message: "Общедомовой чат временно недоступен.")
            
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case .back:
            return .pop()
        }
    }
    
    private func subscribeToNewChatwootNotifications() {
        NotificationCenter.default.rx.notification(.updateChatwootChatSelect)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] notification in
                    guard let self = self,
                          let chat = notification.object as? String else {
                        return
                    }
                    // MARK: Если в стеке уже есть ChatwootViewController - ничего делать не надо
                    guard !(self.rootViewController.viewControllers.contains {
                        $0 is ChatwootViewController
                    }) else {
                        return
                    }
                    // MARK: Если его нет в стеке - принудительно возвращаем юзера на главный экран
                    self.trigger(.chatselect(chat: chat))
                }
            )
            .disposed(by: disposeBag)
    }

}
