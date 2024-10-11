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
    case barrier
    
    var unselectedIcon: UIImage? {
        switch self {
        case .internet: return UIImage(named: "SettingsWiFiUnselectedIcon")
        case .iptv: return UIImage(named: "SettingsMonitorUnselectedIcon")
        case .phone: return UIImage(named: "SettingsCallUnselectedIcon")
        case .domophone: return UIImage(named: "SettingsKeyUnselectedIcon")
        case .cctv: return UIImage(named: "SettingsEyeUnselectedIcon")
        case .ctv: return UIImage(named: "SettingsKabelTVUnselectedIcon")
        case .gsm: return nil
        case .barrier: return UIImage(named: "SettingsBarrierUnselectedIcon")
        }
    }
    
    var selectedIcon: UIImage? {
        switch self {
        case .internet: return UIImage(named: "SettingsWiFiSelectedIcon")
        case .iptv: return UIImage(named: "SettingsMonitorSelectedIcon")
        case .phone: return UIImage(named: "SettingsCallSelectedIcon")
        case .domophone: return UIImage(named: "SettingsKeySelectedIcon")
        case .cctv: return UIImage(named: "SettingsEyeSelectedIcon")
        case .ctv: return UIImage(named: "SettingsKabelTVSelectedIcon")
        case .gsm: return nil
        case .barrier: return UIImage(named: "SettingsBarrierSelectedIcon")
        }
    }
    
    var localizedTitle: String {
        switch self {
        case .internet: return "Интернет"
        case .iptv: return "IP-телевидение"
        case .phone: return "Телефония"
        case .domophone: return "Умный домофон"
        case .cctv: return "Видеонаблюдение"
        case .ctv: return "Кабельное ТВ"
        case .gsm: return "Мобильная связь"
        case .barrier: return "Шлагбаум"
        }
    }
    
    var tooltipTitle: String {
        switch self {
        case .internet: return "интернет"
        case .iptv: return "ip телевидение"
        case .phone: return "телефония"
        case .domophone: return "домофония"
        case .cctv: return "видеонаблюдение"
        case .ctv: return "кабельное тв"
        case .gsm: return "мобильная связь"
        case .barrier: return "шлагбаум"
        }
    }
    
}
