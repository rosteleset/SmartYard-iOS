//
//  SceneDelegate.swift
//  SmartYard
//
//  Created by Александр Попов on 05.10.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private weak var appDelegate: AppDelegate?
    private let quickActionsService = QuickActionsService()
    private var pendingUserActivities: [NSUserActivity] = []

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard session.role == .windowApplication,
              let windowScene = scene as? UIWindowScene,
              let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        self.appDelegate = appDelegate
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.tintColor = UIColor.SmartYard.blue
        window.tintAdjustmentMode = .dimmed

        if Constants.isDarkModeEnabled {
            ThemeManager.shared.applySavedTheme()
        } else {
            ThemeManager.shared.setTheme(.light)
        }
        window.overrideUserInterfaceStyle = ThemeManager.shared.currentTheme.value

        appDelegate.appCoordinator.connect(to: window)
        pendingUserActivities = Array(connectionOptions.userActivities)
        if let shortcutItem = connectionOptions.shortcutItem {
            quickActionsService.storePendingShortcutItem(shortcutItem)
        }

        NotificationCenter.default.removeObserver(self, name: .init("UserLoggedOut"), object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserLoggedOut),
            name: .init("UserLoggedOut"),
            object: nil
        )
        quickActionsService.updateShortcutItems(for: UIApplication.shared)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let appDelegate else { return }
        appDelegate.logLifecycleEvent(AppAnalyticsEvent.appBecameActive)
        let appCoordinator = appDelegate.appCoordinator
        appCoordinator.syncBadgeNumber()
        appCoordinator.markAllMessagesAsDelivered()

        VPNBannerHelper.showIfNeeded()

        let userActivities = pendingUserActivities
        pendingUserActivities.removeAll()
        userActivities.forEach { handle($0) }

        quickActionsService.updateShortcutItems(for: UIApplication.shared)
        quickActionsService.processPendingShortcutIfNeeded { [weak self] shortcutType in
            self?.openTab(for: shortcutType)
        }
        appCoordinator.presentPendingParanoidPushIfNeeded()
        appCoordinator.presentWhatsNewIfNeeded()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        quickActionsService.updateShortcutItems(for: UIApplication.shared)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        appDelegate?.logLifecycleEvent(AppAnalyticsEvent.appEnteredBackground)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        guard let window else { return }
        appDelegate?.appCoordinator.disconnect(from: window)
        window.isHidden = true
        window.rootViewController = nil
        self.window = nil
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(
            quickActionsService.handle(shortcutItem) { [weak self] shortcutType in
                self?.openTab(for: shortcutType)
            }
        )
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handle(userActivity)
    }

    private func handle(_ userActivity: NSUserActivity) {
        switch userActivity.activityType {
        case "INStartVideoCallIntent":
            NotificationCenter.default.post(name: .videoRequestedByCallKit, object: nil)
        case NSUserActivityTypeBrowsingWeb:
            guard let incomingURL = userActivity.webpageURL,
                  let components = URLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
                  components.host == "isdn.lanta.me",
                  components.scheme == "https" else {
                return
            }

            if components.path.matches(pattern: "/[A-Za-z0-9]{10,}") {
                appDelegate?.appCoordinator.trigger(.registerQRCode(code: incomingURL.absoluteString))
            } else if components.path == "/open_app.html" {
                NotificationCenter.default.post(name: .refreshVisibleWebVC, object: nil)
            }
        default:
            break
        }
    }

    private func openTab(for shortcutType: AppShortcutType) {
        guard let appCoordinator = appDelegate?.appCoordinator else { return }
        switch shortcutType {
        case .firstAddressCameras:
            appCoordinator.openFirstAddressCameras()
        case .firstAddressEvents:
            appCoordinator.openFirstAddressEvents()
        case .firstAddressAccess:
            appCoordinator.openFirstAddressAccess()
        case .payments:
            appCoordinator.openPaymentsTab()
        case .settings:
            appCoordinator.openSettingsTab()
        }
    }

    @objc private func handleUserLoggedOut() {
        quickActionsService.updateShortcutItems(for: UIApplication.shared)
    }
}
