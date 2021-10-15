//
//  SettingsAction.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

enum SettingsAction: Hashable {
    
    case openAddressSettings
    case grantAccess
    case openWebVersion
    
    var localizedTitle: String {
        switch self {
        case .openAddressSettings: return "Настройки адреса"
        case .grantAccess: return "Управление доступом"
        case .openWebVersion: return "Открыть веб-версию личного кабинета"
        }
    }
    
}
