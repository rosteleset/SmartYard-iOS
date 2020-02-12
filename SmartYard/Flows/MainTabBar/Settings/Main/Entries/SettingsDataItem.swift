//
//  SettingsDataItem.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxDataSources

enum SettingsDataItem: IdentifiableType, Equatable {
    
    case header(identity: SettingsDataItemIdentity, address: String, contract: String, isExpanded: Bool)
    case controlPanel(identity: SettingsDataItemIdentity, serviceStates: [SettingsServiceType: SettingsServiceState])
    case action(identity: SettingsDataItemIdentity)
    case addAddress
    
}

extension SettingsDataItem {
    
    var identity: SettingsDataItemIdentity {
        switch self {
        case .header(let identity, _, _, _):
            return identity
        case .controlPanel(let identity, _):
            return identity
        case .action(let identity):
            return identity
        case .addAddress:
            return .addAddress
        }
    }
    
}
