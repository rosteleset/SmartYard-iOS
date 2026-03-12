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
        case .openAddressSettings: return L10n.Settings.Main.Address.title
        case .grantAccess: return L10n.Settings.Main.Access.title
        case .openWebVersion: return L10n.Settings.Main.openPersonalAccountWebButton
        }
    }
    
}
