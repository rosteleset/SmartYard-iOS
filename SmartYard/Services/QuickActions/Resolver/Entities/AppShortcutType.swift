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
            return NSLocalizedString("First address cameras", comment: "")
        case .firstAddressEvents:
            return NSLocalizedString("First address events", comment: "")
        case .firstAddressAccess:
            return NSLocalizedString("First address access", comment: "")
        case .payments:
            return NSLocalizedString("Pay", comment: "")
        case .settings:
            return NSLocalizedString("Settings", comment: "")
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
