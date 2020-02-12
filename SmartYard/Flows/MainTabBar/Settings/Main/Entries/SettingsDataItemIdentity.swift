//
//  SettingsDataItemIdentity.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

enum SettingsDataItemIdentity: Hashable {
    
    case header(clientId: String)
    case controlPanel(clientId: String)
    case action(clientId: String, type: SettingsAction)
    case addAddress
    
}
