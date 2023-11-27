//
//  SettingsAction.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
import Foundation

enum SettingsAction: Hashable {
    
    case openAddressSettings
    case grantAccess
    case openWebVersion
    
    var localizedTitle: String {
        switch self {
        case .openAddressSettings: return NSLocalizedString("Address settings", comment: "")
        case .grantAccess: return NSLocalizedString("Access setting", comment: "")
        case .openWebVersion: return NSLocalizedString("Open web version of personal account", comment: "")
        }
    }
    
}
