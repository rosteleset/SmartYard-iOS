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
        case .internet: return NSLocalizedString("Internet", comment: "")
        case .iptv: return "IPTV"
        case .phone: return NSLocalizedString("Wired Phone", comment: "")
        case .domophone: return NSLocalizedString("Smart intercom", comment: "")
        case .cctv: return NSLocalizedString("Video surveillance", comment: "")
        case .ctv: return NSLocalizedString("Cable TV", comment: "")
        case .gsm: return NSLocalizedString("Mobile Phone", comment: "")
        }
    }

    private func getImage(with style: CircleIconStyle) -> UIImage {
        let camView = CircleIconControl(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        camView.style = style
        return camView.asImage()
    }

}
