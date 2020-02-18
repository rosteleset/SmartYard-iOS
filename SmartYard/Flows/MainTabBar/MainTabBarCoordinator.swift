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
    case chat
    case payments
    case settings
}

class MainTabBarCoordinator: TabBarCoordinator<MainTabBarRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let accessService: AccessService
    private let apiWrapper: APIWrapper
    
    private let homeRouter: StrongRouter<HomeRoute>
    private let chatRouter: StrongRouter<ChatRoute>
    private let paymentsRouter: StrongRouter<PaymentsRoute>
    private let settingsRouter: StrongRouter<SettingsRoute>
    
    private let homeTabBarItem: UITabBarItem
    private let chatTabBarItem: UITabBarItem
    private let paymentsTabBarItem: UITabBarItem
    private let settingsTabBarItem: UITabBarItem
    
    // swiftlint:disable:next function_body_length
    init(accessService: AccessService, apiWrapper: APIWrapper) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        
        // MARK: Home Tab
        let homeCoordinator = HomeCoordinator(
            apiWrapper: apiWrapper
        )
        
        let homeTabBarItem = UITabBarItem(
            title: "Адреса",
            image: UIImage(named: "HomeTabUnselected"),
            selectedImage: UIImage(named: "HomeTabSelected")
        )
        
        homeCoordinator.rootViewController.tabBarItem = homeTabBarItem
        self.homeTabBarItem = homeTabBarItem
        
        // MARK: Chat Tab
        let chatCoordinator = ChatCoordinator(
            apiWrapper: apiWrapper
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
        
        // MARK: Settings Tab
        let settingsCoordinator = SettingsCoordinator(
            accessService: accessService,
            apiWrapper: apiWrapper
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
            tabs: [homeRouter, chatRouter, paymentsRouter, settingsRouter],
            select: homeRouter
        )
        
        rootViewController.tabBar.isTranslucent = false
    }
    
    override func prepareTransition(for route: MainTabBarRoute) -> TabBarTransition {
        switch route {
        case .home: return .selectAndCallDelegate(homeRouter)
        case .chat: return .selectAndCallDelegate(chatRouter)
        case .payments: return .selectAndCallDelegate(paymentsRouter)
        case .settings: return .selectAndCallDelegate(settingsRouter)
        }
    }
    
}
