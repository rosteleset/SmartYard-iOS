//
//  AppLaunchStateStore.swift
//  SmartYard
//
//  Created by Александр Попов on 02.08.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import Foundation

struct AppLaunchState {
    let isFirstLaunch: Bool
}

final class AppLaunchStateStore {
    private enum Key {
        static let hasLaunchedBefore = "appLaunchState.hasLaunchedBefore"
        static let legacyAnalyticsFirstOpened = "analytics.app_first_opened_logged"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func registerLaunch() -> AppLaunchState {
        let hasDedicatedState = userDefaults.object(forKey: Key.hasLaunchedBefore) != nil
        let hasLaunchedBefore = hasDedicatedState
            ? userDefaults.bool(forKey: Key.hasLaunchedBefore)
            : userDefaults.bool(forKey: Key.legacyAnalyticsFirstOpened)

        userDefaults.set(true, forKey: Key.hasLaunchedBefore)

        // Keep the previous key during migration so an older build does not log
        // the first-launch analytics event again after a downgrade.
        userDefaults.set(true, forKey: Key.legacyAnalyticsFirstOpened)

        return AppLaunchState(isFirstLaunch: !hasLaunchedBefore)
    }
}
