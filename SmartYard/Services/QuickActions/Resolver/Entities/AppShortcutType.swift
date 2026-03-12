//
//  AppShortcutType.swift
//  SmartYard
//
//  Created by Александр Попов on 27.02.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit

enum AppShortcutType: String {
    case firstAddressCameras = "smartyard.shortcut.firstAddressCameras"
    case firstAddressEvents = "smartyard.shortcut.firstAddressEvents"
    case firstAddressAccess = "com.sesameware.smartyard.shortcut.firstAddressAccess"
    case payments = "smartyard.shortcut.payments"
    case settings = "smartyard.shortcut.settings"


    var shortcutItem: UIApplicationShortcutItem {
        UIApplicationShortcutItem(
            type: rawValue,
            localizedTitle: localizedTitle,
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: iconSystemName),
            userInfo: nil
        )
    }

    private var localizedTitle: String {
        switch self {
        case .firstAddressCameras:
            return L10n.QuickAction.FirstAddress.camerasTitle
        case .firstAddressEvents:
            return L10n.QuickAction.FirstAddress.eventsTitle
        case .firstAddressAccess:
            return L10n.QuickAction.FirstAddress.accessTitle
        case .payments:
            return L10n.Tab.payments
        case .settings:
            return L10n.Common.settings
        }
    }

    private var iconSystemName: String {
        switch self {
        case .firstAddressCameras:
            return "video.fill"
        case .firstAddressEvents:
            return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .firstAddressAccess:
            return "person.badge.key.fill"
        case .payments:
            return "creditcard.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}
