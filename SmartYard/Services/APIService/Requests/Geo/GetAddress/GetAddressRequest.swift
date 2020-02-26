//
//  AddressRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct GetAddressRequest {
    
    let accessToken: String
    let houseId: String
    
}

extension GetAddressRequest {
    
    var requestParameters: [String: Any] {
        return [
            "houseId": houseId
        ]
    }
    
}
