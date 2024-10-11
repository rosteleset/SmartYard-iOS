//
//  GetSetvicesRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct GetServicesRequest {
    
    let accessToken: String
    let houseId: String
    let flat: String?
    
}

extension GetServicesRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "houseId": houseId
        ]
        
        if let flat = flat {
            params["flat"] = flat
        }

        return params
    }
    
}
