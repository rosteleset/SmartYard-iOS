//
//  SettingsDataItem.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxDataSources

enum SettingsDataItem: IdentifiableType, Equatable {
    
    case header(identity: SettingsDataItemIdentity, title: String, subtitle: String, isExpanded: Bool)
    
    case controlPanel(identity: SettingsDataItemIdentity,
        isWiFiEnabled: Bool,
        isMonitorEnabled: Bool,
        isCallEnabled: Bool,
        isKeyEnabled: Bool,
        isEyeEnabled: Bool
    )
    
    case action(identity: SettingsDataItemIdentity, title: String)
    
}

extension SettingsDataItem {
    
    var identity: SettingsDataItemIdentity {
        switch self {
        case .header(let identity, _, _, _):
            return identity
        case .controlPanel(let identity, _, _, _, _, _):
            return identity
        case .action(let identity, _):
            return identity
        }
    }
    
}
