//
//  VPNBannerHelper.swift
//  SmartYard
//
//  Created by Александр Попов on 27.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import NotificationBannerSwift

enum VPNBannerHelper {
    private static var hasShownThisSession = false

    static func showIfNeeded() {
        guard VPNDetector.isVPNActive, !hasShownThisSession else { return }

        StatusBarNotificationBanner(
            title: NSLocalizedString("VPN detected. The application may work unstable.", comment: ""),
            style: .danger,
            colors: SmartYardBannerColors()
        ).show()

        hasShownThisSession = true
    }

    static func reset() {
        hasShownThisSession = false
    }
}
