//
//  MainTabBarCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import XCoordinator
import SSCustomTabbar

enum MainTabBarRoute: Route {
    case home
    case notifications
    case chat
    case payments
    case settings
}

class MainTabBarCoordinator: TabBarCoordinator<MainTabBarRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    private let permissionService: PermissionService
    
    private let homeRouter: StrongRouter<HomeRoute>
    private let notificationsRouter: StrongRouter<NotificationsRoute>
    private let chatRouter: StrongRouter<ChatRoute>
    private let paymentsRouter: StrongRouter<PaymentsRoute>
    private let settingsRouter: StrongRouter<SettingsRoute>
    
    private let homeTabBarItem: UITabBarItem
    private let notificationsTabBarItem: UITabBarItem
    private let chatTabBarItem: UITabBarItem
    private let paymentsTabBarItem: UITabBarItem
    private let settingsTabBarItem: UITabBarItem
    
    // swiftlint:disable:next function_body_length
    init(
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        apiWrapper: APIWrapper,
        issueService: IssueService,
        permissionService: PermissionService
    ) {
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.permissionService = permissionService
        
        // MARK: Home Tab
        let homeCoordinator = HomeCoordinator(
            apiWrapper: apiWrapper,
            pushNotificationService: pushNotificationService,
            accessService: accessService,
            issueService: issueService,
            permissionService: permissionService
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
            pushNotificationService: pushNotificationService
        )
        
        let notificationsTabBarItem = UITabBarItem(
            title: "Уведомления",
            image: UIImage(named: "NotificationsTabUnselected"),
            selectedImage: UIImage(named: "NotificationsTabSelected")
        )
        
        let currentBadgeNumber = UIApplication.shared.applicationIconBadgeNumber
        notificationsTabBarItem.badgeValue = currentBadgeNumber > 0 ? "\(currentBadgeNumber)" : nil
        
        notificationsCoordinator.rootViewController.tabBarItem = notificationsTabBarItem
        self.notificationsTabBarItem = notificationsTabBarItem
        
        // MARK: Chat Tab
        let chatCoordinator = ChatCoordinator(accessService: accessService)
        
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
        
        // MARK: Settings Tab
        let settingsCoordinator = SettingsCoordinator(
            accessService: accessService,
            pushNotificationService: pushNotificationService,
            apiWrapper: apiWrapper,
            issueService: issueService,
            permissionService: permissionService
        )
        
        let settingsTabBarItem = UITabBarItem(
            title: "Настройки",
            image: UIImage(named: "SettingsTabUnselected"),
            selectedImage: UIImage(named: "SettingsTabSelected")
        )
        
        settingsCoordinator.rootViewController.tabBarItem = settingsTabBarItem
        self.settingsTabBarItem = settingsTabBarItem
        
        // MARK: Initialization
        self.homeRouter = homeCoordinator.strongRouter
        self.notificationsRouter = notificationsCoordinator.strongRouter
        self.chatRouter = chatCoordinator.strongRouter
        self.paymentsRouter = paymentsCoordinator.strongRouter
        self.settingsRouter = settingsCoordinator.strongRouter
        
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
        
        super.init(
            rootViewController: customTabBarController,
            tabs: [homeRouter, notificationsRouter, chatRouter, paymentsRouter, settingsRouter],
            select: homeRouter
        )
        
        rootViewController.tabBar.isTranslucent = false
        
        subscribeToBadgeUpdates()
        subscribeToAddAddressNotifications()
        subscribeToChatNotifications()
    }
    
    override func prepareTransition(for route: MainTabBarRoute) -> TabBarTransition {
        switch route {
        case .home: return .selectAndCallDelegate(homeRouter)
        case .notifications: return .selectAndCallDelegate(notificationsRouter)
        case .chat: return .selectAndCallDelegate(chatRouter)
        case .payments: return .selectAndCallDelegate(paymentsRouter)
        case .settings: return .selectAndCallDelegate(settingsRouter)
        }
    }
    
    private func subscribeToBadgeUpdates() {
        NotificationCenter.default.rx
            .notification(Notification.Name.badgeNumberUpdated)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] notification in
                    guard let badgeNumber = notification.userInfo?[NotificationKeys.badgeNumberKey] as? Int else {
                        return
                    }
                    
                    self?.notificationsTabBarItem.badgeValue = badgeNumber > 0 ? "\(badgeNumber)" : nil
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
    
}
