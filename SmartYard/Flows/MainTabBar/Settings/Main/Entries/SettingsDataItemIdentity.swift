//
//  SettingsDataItemIdentity.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

enum SettingsDataItemIdentity: Hashable {
    
    case header(uniqueId: String)
    case controlPanel(uniqueId: String)
    case action(uniqueId: String, type: SettingsAction)
    case addAddress
    
}
