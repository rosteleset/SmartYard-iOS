//
//  SmartYardBannerColors.swift
//  SmartYard
//
//  Created by Александр Попов on 27.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import NotificationBannerSwift

final class SmartYardBannerColors: BannerColorsProtocol {

    func color(for style: NotificationBannerSwift.BannerStyle) -> UIColor {
        switch style {
        case .danger: return .SmartYard.incorrectDataRed
        case .info: return .SmartYard.grayBorder
        case .success: return .SmartYard.darkGreen
        default : return UIColor.clear
        }
    }

}
