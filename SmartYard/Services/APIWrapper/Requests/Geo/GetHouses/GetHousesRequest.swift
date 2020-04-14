//
//  GetHousesRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct GetHousesRequest {
    
    let accessToken: String
    let streetId: String
    
}

extension GetHousesRequest {
    
    var requestParameters: [String: Any] {
        return [
            "streetId": streetId
        ]
    }
    
}
