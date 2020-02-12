//
//  SettingsServiceType.swift
//  SmartYard
//
//  Created by admin on 12/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

enum SettingsServiceType {
    
    case internet
    case tv
    case phone
    case lock
    case camera
    
    var unselectedIcon: UIImage? {
        switch self {
        case .internet: return UIImage(named: "SettingsWiFiUnselectedIcon")
        case .tv: return UIImage(named: "SettingsMonitorUnselectedIcon")
        case .phone: return UIImage(named: "SettingsCallUnselectedIcon")
        case .lock: return UIImage(named: "SettingsKeyUnselectedIcon")
        case .camera: return UIImage(named: "SettingsEyeUnselectedIcon")
        }
    }
    
    var selectedIcon: UIImage? {
        switch self {
        case .internet: return UIImage(named: "SettingsWiFiSelectedIcon")
        case .tv: return UIImage(named: "SettingsMonitorSelectedIcon")
        case .phone: return UIImage(named: "SettingsCallSelectedIcon")
        case .lock: return UIImage(named: "SettingsKeySelectedIcon")
        case .camera: return UIImage(named: "SettingsEyeSelectedIcon")
        }
    }
    
}
