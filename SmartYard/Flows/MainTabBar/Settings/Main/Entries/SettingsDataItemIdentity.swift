//
//  SettingsDataItemIdentity.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

enum SettingsDataItemIdentity: Hashable {
    
    case header(addressId: String)
    case controlPanel(addressId: String)
    case action(addressId: String, address: String, type: SettingsAction)
    case addAddress
    
}
