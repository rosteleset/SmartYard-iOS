//
//  GetLocationsRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct GetAllLocationsRequest {
    
    let accessToken: String
    
}

extension GetAllLocationsRequest {
    
    var requestParameters: [String: Any] {
        return [:]
    }
    
}
