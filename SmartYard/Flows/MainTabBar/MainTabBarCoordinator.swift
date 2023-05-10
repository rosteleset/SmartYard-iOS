//
//  MainTabBarCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable type_body_length function_body_length line_length file_length

import UIKit
import RxSwift
import RxCocoa
import XCoordinator
import SSCustomTabbar

enum MainTabBarRoute: Route {
    case home
    case notifications
    case chat
    case chatwoot
    case payments
    case settings
    case menu
}

class MainTabBarCoordinator: TabBarCoordinator<MainTabBarRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    private let permissionService: PermissionService
    private let alertService: AlertService
    private let logoutHelper: LogoutHelper
    
    private let homeRouter: StrongRouter<HomeRoute>
    private let notificationsRouter: StrongRouter<NotificationsRoute>
    private let chatRouter: StrongRouter<ChatRoute>
    private let chatwootRouter: StrongRouter<ChatwootRoute>
    private let paymentsRouter: StrongRouter<PaymentsRoute>
    private let menuRouter: StrongRouter<MainMenuRoute>
    
    private let homeTabBarItem: UITabBarItem
    private let notificationsTabBarItem: UITabBarItem
    private let chatTabBarItem: UITabBarItem
    private let chatwootTabBarItem: UITabBarItem
    private let paymentsTabBarItem: UITabBarItem
    private let menuTabBarItem: UITabBarItem
    
    var selectedPresentable: Presentable? {
        return children[safe: rootViewController.selectedIndex]
    }
    
    init(
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        apiWrapper: APIWrapper,
        issueService: IssueService,
        permissionService: PermissionService,
        alertService: AlertService,
        logoutHelper: LogoutHelper
    ) {
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.permissionService = permissionService
        self.alertService = alertService
        self.logoutHelper = logoutHelper
        
        // MARK: Home Tab
        let homeCoordinator = HomeCoordinator(
            apiWrapper: apiWrapper,
            pushNotificationService: pushNotificationService,
            accessService: accessService,
            issueService: issueService,
            permissionService: permissionService,
            alertService: alertService,
            logoutHelper: logoutHelper
        )
        
        let homeTabBarItem = UITabBarItem(
            title: "Адреса",
            image: UIImage(named: "HomeTabUnselected"),
            selectedImage: UIImage(named: "HomeTabSelected")
        )
        
        homeCoordinator.rootViewController.tabBarItem = homeTabBarItem
        self.homeTabBarItem = homeTabBarItem
        
        // MARK: Notifications Tab
        
        let notificationsCoordinator = NotificationsCoordinator(
            apiWrapper: apiWrapper,
            pushNotificationService: pushNotificationService,
            logoutHelper: logoutHelper,
            alertService: alertService
        )
        
        let notificationsTabBarItem = UITabBarItem(
            title: "Уведомления",
            image: UIImage(named: "NotificationsTabUnselected"),
            selectedImage: UIImage(named: "NotificationsTabSelected")
        )
        
        notificationsCoordinator.rootViewController.tabBarItem = notificationsTabBarItem
        self.notificationsTabBarItem = notificationsTabBarItem
        
        // MARK: Chatwoot in Chat Tab
        let chatwootCoordinator = ChatwootCoordinator(
            apiWrapper: apiWrapper,
            accessService: accessService,
            pushNotificationService: pushNotificationService,
            logoutHelper: logoutHelper,
            alertService: alertService
        )

        let chatwootTabBarItem = UITabBarItem(
            title: "Чат",
            image: UIImage(named: "ChatTabUnselected"),
            selectedImage: UIImage(named: "ChatTabSelected")
        )

        chatwootCoordinator.rootViewController.tabBarItem = chatwootTabBarItem
        self.chatwootTabBarItem = chatwootTabBarItem
        
        // MARK: Chat Tab
        let chatCoordinator = ChatCoordinator(
            apiWrapper: apiWrapper,
            accessService: accessService,
            pushNotificationService: pushNotificationService,
            logoutHelper: logoutHelper,
            alertService: alertService
        )

        let chatTabBarItem = UITabBarItem(
            title: "Чат",
            image: UIImage(named: "ChatTabUnselected"),
            selectedImage: UIImage(named: "ChatTabSelected")
        )

        chatCoordinator.rootViewController.tabBarItem = chatTabBarItem
        self.chatTabBarItem = chatTabBarItem

        // MARK: Payments Tab
        let paymentsCoordinator = PaymentsCoordinator(
            apiWrapper: apiWrapper
        )
        
        let paymentsTabBarItem = UITabBarItem(
            title: "Оплатить",
            image: UIImage(named: "PaymentsTabUnselected"),
            selectedImage: UIImage(named: "PaymentsTabSelected")
        )
        
        paymentsCoordinator.rootViewController.tabBarItem = paymentsTabBarItem
        self.paymentsTabBarItem = paymentsTabBarItem
        
        // MARK: Menu Tab
        let menuCoordinator = MainMenuCoordinator(
            accessService: accessService,
            pushNotificationService: pushNotificationService,
            apiWrapper: apiWrapper,
            issueService: issueService,
            permissionService: permissionService,
            logoutHelper: logoutHelper,
            alertService: alertService
            
        )
        
        let menuTabBarItem = UITabBarItem(
            title: "Меню",
            image: UIImage(named: "MenuTabUnselected"),
            selectedImage: UIImage(named: "MenuTabSelected")
        )
        
        menuCoordinator.rootViewController.tabBarItem = menuTabBarItem
        self.menuTabBarItem = menuTabBarItem
        
        // MARK: Initialization
        self.homeRouter = homeCoordinator.strongRouter
        self.notificationsRouter = notificationsCoordinator.strongRouter
        self.chatRouter = chatCoordinator.strongRouter
        self.chatwootRouter = chatwootCoordinator.strongRouter
        self.paymentsRouter = paymentsCoordinator.strongRouter
        self.menuRouter = menuCoordinator.strongRouter
        
        // MARK: Инициализация кастомного UITabBarController
        
        let nib = UINib(nibName: "CustomTabBarController", bundle: .main)
        
        guard let customTabBarController = nib.instantiate(
            withOwner: nil,
            options: nil
        ).first as? SSCustomTabBarViewController else {
            fatalError("Failed to load custom UITabBarController")
        }
        
        customTabBarController.animationConfiguration = AnimationConfiguration(
            duration: 0.5,
            delay: 0,
            springDampingRatio: 0.65,
            initialSpringVelocity: 0
        )
        customTabBarController.tabBar.tintColor = UIColor(hex: 0xE41A4C)
        customTabBarController.delegate = customTabBarController
        
        let tabs = accessService.showPayments ?
            [homeRouter, notificationsRouter, chatwootRouter, paymentsRouter, menuRouter] as [Presentable] :
            [homeRouter, notificationsRouter, chatwootRouter, menuRouter] as [Presentable]
//        [homeRouter, notificationsRouter, chatRouter, paymentsRouter, menuRouter] as [Presentable] :
//        [homeRouter, notificationsRouter, chatRouter, menuRouter] as [Presentable]

        super.init(
            rootViewController: customTabBarController,
            tabs: tabs,
            select: homeRouter
        )
        
        updateNotificationsTab(shouldShowBadge: UIApplication.shared.applicationIconBadgeNumber > 0)
        
        rootViewController.tabBar.isTranslucent = false
        
        subscribeToBadgeUpdates()
        subscribeToAddAddressNotifications()
        subscribeToChatwootNotifications()
//        subscribeToChatNotifications()
        subscribeToOptionsNotifications()
    }
    
    override func prepareTransition(for route: MainTabBarRoute) -> TabBarTransition {
        switch route {
        case .home:
            print("home")
            return .selectAndCallDelegate(homeRouter)
        case .notifications:
            print("notifications")
            return .selectAndCallDelegate(notificationsRouter)
        case .chat:
            print("chat")
            return .selectAndCallDelegate(chatRouter)
        case .chatwoot:
            print("chatwoot")
            return .selectAndCallDelegate(chatwootRouter)
        case .payments:
            print("payments")
            return .selectAndCallDelegate(paymentsRouter)
        case .settings:
            print("TODO: проверить переадресацию в настройки")
            return .trigger(MainMenuRoute.settings, on: menuRouter)
            // selectAndCallDelegate(settingsRouter)
        case .menu:
            print("menu")
            return .selectAndCallDelegate(menuRouter)
        }
    }
    
    private func updateNotificationsTab(shouldShowBadge: Bool) {
        notificationsTabBarItem.image = UIImage(
            named: shouldShowBadge ? "NotificationsTabBadgeUnselected" : "NotificationsTabUnselected"
        )
        
        notificationsTabBarItem.selectedImage = UIImage(
            named: shouldShowBadge ? "NotificationsTabBadgeSelected" : "NotificationsTabSelected"
        )
        
        notificationsTabBarItem.imageInsets = shouldShowBadge ?
            UIEdgeInsets(top: -2, left: 0, bottom: 2, right: 0) :
            .zero
    }
    
    private func updateChatTab(shouldShowBadge: Bool) {
        chatTabBarItem.image = UIImage(
            named: shouldShowBadge ? "ChatTabBadgeUnselected" : "ChatTabUnselected"
        )
        
        chatTabBarItem.selectedImage = UIImage(
            named: shouldShowBadge ? "ChatTabBadgeSelected" : "ChatTabSelected"
        )
        
        chatTabBarItem.imageInsets = shouldShowBadge ?
            UIEdgeInsets(top: -2, left: 0, bottom: 2, right: 0) :
            .zero
    }
    
    private func subscribeToBadgeUpdates() {
        NotificationCenter.default.rx
            .notification(.unreadInboxMessagesAvailable)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    self?.updateNotificationsTab(shouldShowBadge: true)
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.allInboxMessagesRead)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    self?.updateNotificationsTab(shouldShowBadge: false)
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.unreadChatwootMessagesAvailable)
//            .notification(.unreadChatMessagesAvailable)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    self?.updateChatTab(shouldShowBadge: true)
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.allChatMessagesRead)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    self?.updateChatTab(shouldShowBadge: false)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func subscribeToAddAddressNotifications() {
        NotificationCenter.default.rx
            .notification(Notification.Name.addAddressFromSettings)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
            .drive(
                onNext: { [weak self] in
                    self?.trigger(.home)
                    self?.homeRouter.trigger(.inputContract(isManualTrigger: true))
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func subscribeToChatNotifications() {
        NotificationCenter.default.rx
            .notification(Notification.Name.chatRequested)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
            .drive(
                onNext: { [weak self] in
                    self?.trigger(.chat)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func subscribeToChatwootNotifications() {
        NotificationCenter.default.rx
            .notification(Notification.Name.chatwootRequested)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
            .drive(
                onNext: { [weak self] in
                    self?.trigger(.chatwoot)
                }
            )
            .disposed(by: disposeBag)
    }
    
    fileprivate func updatePaymentsVisibility(_ payments: Bool, _ self: MainTabBarCoordinator) {
        if payments,
           self.rootViewController.viewControllers?.contains(self.paymentsRouter.viewController) == false {
            self.rootViewController.viewControllers?.insert(self.paymentsRouter.viewController, at: 3)
            self.addChild(paymentsRouter)
        } else if !payments {
            self.rootViewController.viewControllers?.removeAll(self.paymentsRouter.viewController)
            self.removeChild(paymentsRouter)
        }
        
    }
    
    private func subscribeToOptionsNotifications() {
        // Управляет скрытием пунктов в таббаре
        NotificationCenter.default.rx
            .notification(Notification.Name.updateOptions)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] notification in
                    if let self = self,
                       let userInfo = notification.userInfo,
                       let payments = userInfo["payments"] as? Bool {
                        self.updatePaymentsVisibility(payments, self)
                        self.accessService.showPayments = payments
                    }
                    
                    // обновляем телефон техподдержки
                    if let self = self,
                       let userInfo = notification.userInfo,
                       let supportPhone = userInfo["supportPhone"] as? String {
                        self.accessService.supportPhone = supportPhone
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension SSCustomTabBarViewController: UITabBarControllerDelegate {
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // делаем так, чтобы при нажатии на пункт "меню" мы всегда переходили на экран с меню, для этого очищаем Navigation stack
        if tabBarController.selectedIndex == 4,
            let vc = viewController as? UINavigationController {
            vc.popToRootViewController(animated: false)
        }
        
    }
}
