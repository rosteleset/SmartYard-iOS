//
//  SettingsServiceType.swift
//  SmartYard
//
//  Created by admin on 12/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

enum SettingsServiceType: String {
    
    case internet
    case iptv
    case ctv
    case phone
    case cctv
    case domophone
    case gsm
    
    var unselectedIcon: UIImage? {
        switch self {
        case .internet: return getImage(with: .Settings.Unselected.wifi)
        case .iptv: return getImage(with: .Settings.Unselected.monitor)
        case .phone: return getImage(with: .Settings.Unselected.call)
        case .domophone: return getImage(with: .Settings.Unselected.key)
        case .cctv: return getImage(with: .Settings.Unselected.eye)
        case .ctv: return nil
        case .gsm: return nil
        }
    }
    
    var selectedIcon: UIImage? {
        switch self {
        case .internet: return getImage(with: .Settings.Selected.wifi)
        case .iptv: return getImage(with: .Settings.Selected.monitor)
        case .phone: return getImage(with: .Settings.Selected.call)
        case .domophone: return getImage(with: .Settings.Selected.key)
        case .cctv: return getImage(with: .Settings.Selected.eye)
        case .ctv: return nil
        case .gsm: return nil
        }
    }
    
    var localizedTitle: String {
        switch self {
        case .internet: return L10n.Services.Catalog.internet
        case .iptv: return "IPTV"
        case .phone: return L10n.Services.Catalog.wiredPhone
        case .domophone: return L10n.Services.Catalog.smartIntercom
        case .cctv: return L10n.Services.Catalog.videoSurveillance
        case .ctv: return L10n.Services.Catalog.cableTV
        case .gsm: return L10n.Services.Catalog.mobilePhone
        }
    }

    private func getImage(with style: CircleIconStyle) -> UIImage {
        let camView = CircleIconControl(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        camView.style = style
        return camView.asImage()
    }

}
