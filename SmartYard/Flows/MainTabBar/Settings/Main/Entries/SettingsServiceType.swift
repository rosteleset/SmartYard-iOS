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
        case .internet: return UIImage(named: "SettingsWiFiUnselectedIcon")
        case .iptv: return UIImage(named: "SettingsMonitorUnselectedIcon")
        case .phone: return UIImage(named: "SettingsCallUnselectedIcon")
        case .domophone: return UIImage(named: "SettingsKeyUnselectedIcon")
        case .cctv: return UIImage(named: "SettingsEyeUnselectedIcon")
        case .ctv: return nil
        case .gsm: return nil
        }
    }
    
    var selectedIcon: UIImage? {
        switch self {
        case .internet: return UIImage(named: "SettingsWiFiSelectedIcon")
        case .iptv: return UIImage(named: "SettingsMonitorSelectedIcon")
        case .phone: return UIImage(named: "SettingsCallSelectedIcon")
        case .domophone: return UIImage(named: "SettingsKeySelectedIcon")
        case .cctv: return UIImage(named: "SettingsEyeSelectedIcon")
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
    
}
