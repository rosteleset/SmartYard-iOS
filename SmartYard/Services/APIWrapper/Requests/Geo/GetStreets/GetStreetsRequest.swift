//
//  GetStreetsRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct GetStreetsRequest {
    
    let accessToken: String
    let locationId: String
    
}

extension GetStreetsRequest {
    
    var requestParameters: [String: Any] {
        return [
            "locationId": locationId
        ]
    }
    
}
