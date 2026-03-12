//
//  MainTabBarCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
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
    case menu
}

// swiftlint: disable type_body_length
final class MainTabBarCoordinator: TabBarCoordinator<MainTabBarRoute>, HasDisposeBag {

    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    private let permissionService: PermissionService
    private let alertService: AlertService
    private let logoutHelper: LogoutHelper
    private let offlineAddressListDataSource: OfflineAddressListDataSource
    private let networkStateProvider: NetworkStateProviding
    private let optionsService: OptionsServicing

    private let homeRouter: StrongRouter<HomeRoute>
    private let notificationsRouter: StrongRouter<NotificationsRoute>
    private let chatRouter: StrongRouter<ChatRoute>
    private let paymentsRouter: StrongRouter<PaymentsRoute>
    private let menuRouter: StrongRouter<MainMenuRoute>

    private let homeTabBarItem: UITabBarItem
    private let notificationsTabBarItem: UITabBarItem
    private let chatTabBarItem: UITabBarItem
    private let paymentsTabBarItem: UITabBarItem
    private let menuTabBarItem: UITabBarItem

    private lazy var eventsBinder: MainTabBarEventsBinding = MainTabBarEventsBinder(
        optionsService: optionsService
    )
    private lazy var quickActionOpener: MainTabBarQuickActionOpening = MainTabBarQuickActionOpener(
        resolver: QuickActionResolverService(
            apiWrapper: apiWrapper,
            accessService: accessService
        ),
        homeRouter: homeRouter,
        menuRouter: menuRouter,
        selectTab: { [weak self] route in
            self?.trigger(route)
        },
        alertService: alertService
    )

    var selectedPresentable: Presentable? {
        return children[safe: rootViewController.selectedIndex]
    }

    // swiftlint:disable:next function_body_length
    init(
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        apiWrapper: APIWrapper,
        issueService: IssueService,
        permissionService: PermissionService,
        alertService: AlertService,
        logoutHelper: LogoutHelper,
        offlineAddressListDataSource: OfflineAddressListDataSource,
        networkStateProvider: NetworkStateProviding,
        optionsService: OptionsServicing,
        supportCallActionsPresenter: SupportCallActionsPresenting,
        requestSupportCallbackUseCase: RequestSupportCallbackUseCase,
        phoneDialer: PhoneDialing
    ) {
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.permissionService = permissionService
        self.alertService = alertService
        self.logoutHelper = logoutHelper
        self.offlineAddressListDataSource = offlineAddressListDataSource
        self.networkStateProvider = networkStateProvider
        self.optionsService = optionsService

        // MARK: Home Tab
        let homeCoordinator = HomeCoordinator(
            apiWrapper: apiWrapper,
            pushNotificationService: pushNotificationService,
            accessService: accessService,
            issueService: issueService,
            permissionService: permissionService,
            alertService: alertService,
            logoutHelper: logoutHelper,
            offlineAddressListDataSource: offlineAddressListDataSource,
            networkStateProvider: networkStateProvider
        )

        let homeTabBarItem = UITabBarItem(
            title: L10n.Tab.addresses,
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
            alertService: alertService,
            networkStateProvider: networkStateProvider
        )
        
        let notificationsTabBarItem = UITabBarItem(
            title: L10n.Tab.notifications,
            image: UIImage(named: "NotificationsTabUnselected"),
            selectedImage: UIImage(named: "NotificationsTabSelected")
        )
        
        notificationsCoordinator.rootViewController.tabBarItem = notificationsTabBarItem
        self.notificationsTabBarItem = notificationsTabBarItem
        
        // MARK: Chat Tab
        let chatCoordinator = ChatCoordinator(
            apiWrapper: apiWrapper,
            accessService: accessService,
            pushNotificationService: pushNotificationService,
            logoutHelper: logoutHelper,
            alertService: alertService,
            networkStateProvider: networkStateProvider
        )
        
        let chatTabBarItem = UITabBarItem(
            title: L10n.Tab.chat,
            image: UIImage(named: "ChatTabUnselected"),
            selectedImage: UIImage(named: "ChatTabSelected")
        )
        
        chatCoordinator.rootViewController.tabBarItem = chatTabBarItem
        self.chatTabBarItem = chatTabBarItem

        // MARK: Payments Tab
        let paymentsCoordinator = PaymentsCoordinator(
            apiWrapper: apiWrapper,
            networkStateProvider: networkStateProvider
        )

        let paymentsTabBarItem = UITabBarItem(
            title: L10n.Tab.payments,
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
            alertService: alertService,
            networkStateProvider: networkStateProvider,
            supportCallActionsPresenter: supportCallActionsPresenter,
            requestSupportCallbackUseCase: requestSupportCallbackUseCase,
            phoneDialer: phoneDialer
        )

        let menuTabBarItem = UITabBarItem(
            title: L10n.Tab.menu,
            image: UIImage(named: "MenuTabUnselected"),
            selectedImage: UIImage(named: "MenuTabSelected")
        )

        menuCoordinator.rootViewController.tabBarItem = menuTabBarItem
        self.menuTabBarItem = menuTabBarItem

        // MARK: Initialization
        self.homeRouter = homeCoordinator.strongRouter
        self.notificationsRouter = notificationsCoordinator.strongRouter
        self.chatRouter = chatCoordinator.strongRouter
        self.paymentsRouter = paymentsCoordinator.strongRouter
        self.menuRouter = menuCoordinator.strongRouter

        // MARK: Инициализация кастомного/системного UITabBarController
        let isNewTabBarActive = true
        let rootTabBarController: UITabBarController
        if #available(iOS 26.0, *), isNewTabBarActive {
            // На iOS 26+ используем стандартный UITabBarController
            rootTabBarController = UITabBarController()
        } else {
            // Загрузка кастомного таббара из nib как и раньше
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
            customTabBarController.delegate = customTabBarController
            rootTabBarController = customTabBarController
        }

        let tabs: [Presentable] = {
            var tabs: [Presentable] = [homeCoordinator.strongRouter, notificationsCoordinator.strongRouter]

            if accessService.showChat { tabs.append(chatCoordinator.strongRouter) }
            if accessService.showPayments { tabs.append(paymentsCoordinator.strongRouter) }

            tabs.append(menuCoordinator.strongRouter)
            return tabs
        }()

        super.init(
            rootViewController: rootTabBarController,
            tabs: tabs,
            select: homeRouter
        )

        if #available(iOS 26.0, *), isNewTabBarActive {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()

            rootTabBarController.tabBar.standardAppearance = appearance
            rootTabBarController.tabBar.scrollEdgeAppearance = appearance
            rootTabBarController.tabBar.isTranslucent = true

            rootTabBarController.view.layoutIfNeeded()
            rootTabBarController.tabBar.layoutIfNeeded()
        } else {
            // Fallback on earlier versions
        }

        updateNotificationsTab(shouldShowBadge: UIApplication.shared.applicationIconBadgeNumber > 0)

        bind()
    }

    override func prepareTransition(for route: MainTabBarRoute) -> TabBarTransition {
        switch route {
        case .home:
            Logger.logDebug("MainTabBarRoute → home")
            return .selectAndCallDelegate(homeRouter)
        case .notifications:
            Logger.logDebug("MainTabBarRoute → notifications")
            return .selectAndCallDelegate(notificationsRouter)
        case .chat:
            Logger.logDebug("MainTabBarRoute → chat")
            return .selectAndCallDelegate(chatRouter)
        case .payments:
            Logger.logDebug("MainTabBarRoute → payments")
            return .selectAndCallDelegate(paymentsRouter)
        case .settings:
            // TODO: - проверить переадресацию
            Logger.logInfo("MainTabBarRoute → settings")
            return .trigger(MainMenuRoute.settings, on: menuRouter)
            // .selectAndCallDelegate(settingsRouter)
        case .menu:
            Logger.logDebug("MainTabBarRoute → menu")
            return .selectAndCallDelegate(menuRouter)
        }
    }

    func openFirstAddressCameras() {
        quickActionOpener.open(.firstAddressCameras)
    }

    func openFirstAddressEvents() {
        quickActionOpener.open(.firstAddressEvents)
    }

    func openFirstAddressAccess() {
        quickActionOpener.open(.firstAddressAccess)
    }
}

private extension MainTabBarCoordinator {

    func bind() {
        eventsBinder.notificationsBadgeChanged
            .drive(with: self) { owner, shouldShowBadge in
                owner.updateNotificationsTab(shouldShowBadge: shouldShowBadge)
            }
            .disposed(by: disposeBag)

        eventsBinder.chatBadgeChanged
            .drive(with: self) { owner, shouldShowBadge in
                owner.updateChatTab(shouldShowBadge: shouldShowBadge)
            }
            .disposed(by: disposeBag)

        eventsBinder.addAddressRequested
            .emit(with: self) { owner, _ in
                owner.trigger(.home)
                owner.homeRouter.trigger(.inputContract(isManualTrigger: true))
            }
            .disposed(by: disposeBag)

        eventsBinder.chatRequested
            .emit(with: self) { owner, _ in
                owner.trigger(.chat)
            }
            .disposed(by: disposeBag)

        eventsBinder.optionsUpdated
            .drive(with: self) { owner, _ in
                owner.reloadTabs()
                owner.selectTabIfNeeded()
            }
            .disposed(by: disposeBag)
    }

    func selectTabIfNeeded() {
        let desiredRouter = desiredRouter()

        let viewControllers = rootViewController.viewControllers ?? []

        if let index = viewControllers.firstIndex(where: {
            $0 === desiredRouter.viewController
        }) {
            rootViewController.selectedIndex = index
        } else {
            rootViewController.selectedIndex = 0
        }
    }

    func makeTabs() -> [Presentable] {
        var tabs: [Presentable] = [homeRouter, notificationsRouter]

        if accessService.showChat { tabs.append(chatRouter) }
        if accessService.showPayments { tabs.append(paymentsRouter) }

        tabs.append(menuRouter)

        return tabs
    }

    func reloadTabs() {
        let tabs = makeTabs()
        rootViewController.setViewControllers(
            tabs.map { $0.viewController },
            animated: false
        )
    }

    func desiredRouter() -> Presentable {
        switch accessService.activeTab {
        case "addresses": return homeRouter
        case "notifications": return notificationsRouter
        case "chat": return chatRouter
        case "pay": return paymentsRouter
        case "menu": return menuRouter
        default: return homeRouter
        }
    }

    func updateNotificationsTab(shouldShowBadge: Bool) {
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

    func updateChatTab(shouldShowBadge: Bool) {
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
