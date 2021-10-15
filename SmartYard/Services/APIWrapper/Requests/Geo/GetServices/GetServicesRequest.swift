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
    
}

extension GetServicesRequest {
    
    var requestParameters: [String: Any] {
        return [
            "houseId": houseId
        ]
    }
    
}
