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

final class ChatCoordinator: NavigationCoordinator<ChatRoute>, HasDisposeBag {
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    private let networkStateProvider: NetworkStateProviding
    var childCoordinator: WebViewCoordinator?
    
    
    init(
        apiWrapper: APIWrapper,
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        networkStateProvider: NetworkStateProviding
    ) {
        self.apiWrapper = apiWrapper
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.networkStateProvider = networkStateProvider

        super.init(initialRoute: Self.route(for: accessService))

        rootViewController.setNavigationBarHidden(true, animated: false)
        subscribeToOptionsUpdates()
    }
    
    override func prepareTransition(for route: ChatRoute) -> NavigationTransition {
        switch route {
        case .main:
            children.forEach { removeChild($0) }

            let vm = ChatViewModel(
                apiWrapper: apiWrapper,
                accessService: accessService,
                pushNotificationService: pushNotificationService,
                logoutHelper: logoutHelper,
                alertService: alertService,
                networkStateProvider: networkStateProvider
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
                networkStateProvider: networkStateProvider,
                url: url,
                backButtonLabel: "",
                push: false,
                version: 2,
                refreshControl: false
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

private extension ChatCoordinator {

    func subscribeToOptionsUpdates() {
        accessService.optionsUpdated
            .asDriverOnErrorJustComplete()
            .drive(with: self) { owner, _ in
                owner.trigger(Self.route(for: owner.accessService))
            }
            .disposed(by: disposeBag)
    }

    static func route(for accessService: AccessService) -> ChatRoute {
        let chatUrl = accessService.chatUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !chatUrl.isEmpty else {
            return .main
        }

        guard let encodedUrl = chatUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedUrl) else {
            return .alert(
                title: L10n.Common.error,
                message: L10n.Chat.Error.unableToOpenPage
            )
        }

        return .webView(url: url)
    }

}
