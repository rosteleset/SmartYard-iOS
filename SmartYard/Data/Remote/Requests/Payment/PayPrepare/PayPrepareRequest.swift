//
//  PreparePay.swift
//  SmartYard
//
//  Created by Mad Brains on 14.05.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct PayPrepareRequest {
    
    let accessToken: String
    let clientId: String
    let amount: String
    
}

extension PayPrepareRequest {
    
    var requestParameters: [String: Any] {
        return [
            "clientId": clientId,
            "amount": amount
        ]
    }
    
}
