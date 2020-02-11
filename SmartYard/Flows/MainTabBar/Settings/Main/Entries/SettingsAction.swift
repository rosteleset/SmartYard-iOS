//
//  SettingsAction.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

enum SettingsAction: Hashable {
    
    case openAddressSettings
    case grantAccess
    case openWebVersion
    
    var localizedTitle: String {
        switch self {
        case .openAddressSettings: return "Открыть настройки адреса"
        case .grantAccess: return "Предоставить доступ"
        case .openWebVersion: return "Открыть веб-версию личного кабинета"
        }
    }
    
}
