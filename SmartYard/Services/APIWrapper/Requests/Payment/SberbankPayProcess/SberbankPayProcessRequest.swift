//
//  SberbankPayProcessRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 14.05.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct SberbankPayProcessRequest {
    
    let merchant: String
    let orderNumber: String
    let paymentToken: String
    
}

extension SberbankPayProcessRequest {
    
    var requestParameters: [String: Any] {
        return [
            "merchant": merchant,
            "orderNumber": orderNumber,
            "paymentToken": paymentToken
        ]
    }
    
}
