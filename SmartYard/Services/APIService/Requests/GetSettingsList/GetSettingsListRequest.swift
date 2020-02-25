//
//  GetSettingsTabAddresses.swift
//  SmartYard
//
//  Created by Mad Brains on 25.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct GetSettingsListRequest {
    
    let accessToken: String
    
}

extension GetSettingsListRequest {
    
    var requestParameters: [String: Any] {
        return [:]
    }
    
}
