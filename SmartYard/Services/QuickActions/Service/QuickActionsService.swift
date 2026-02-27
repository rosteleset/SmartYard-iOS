//
//  QuickActionsService.swift
//  SmartYard
//
//  Created by Александр Попов on 27.02.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit

final class QuickActionsService {
    private let accessService: AccessService
    private var pendingShortcutItem: UIApplicationShortcutItem?

    init(accessService: AccessService = .shared) {
        self.accessService = accessService
    }

    func updateShortcutItems(for application: UIApplication) {
        application.shortcutItems = availableShortcutTypes().map { $0.shortcutItem }
    }

    func storePendingShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        pendingShortcutItem = shortcutItem
    }

    func processPendingShortcutIfNeeded(handler: (AppShortcutType) -> Void) {
        guard let pendingShortcutItem else { return }
        _ = handle(pendingShortcutItem, handler: handler)
        self.pendingShortcutItem = nil
    }

    @discardableResult
    func handle(_ shortcutItem: UIApplicationShortcutItem, handler: (AppShortcutType) -> Void) -> Bool {
        guard
            let type = AppShortcutType(rawValue: shortcutItem.type),
            availableShortcutTypes().contains(type)
        else {
            return false
        }

        handler(type)
        return true
    }
}

private extension QuickActionsService {
    func availableShortcutTypes() -> [AppShortcutType] {
        guard accessService.hasValidToken else { return [] }

        var shortcutTypes: [AppShortcutType] = [
            .firstAddressCameras,
            .firstAddressEvents,
            .firstAddressAccess
        ]

        // iOS quick actions are limited, so use either Payments or Settings in the 4th slot.
        // Payments > Settings
        shortcutTypes.append(accessService.showPayments ? .payments : .settings)

        return Array(shortcutTypes.prefix(4))
    }
}
