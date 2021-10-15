//
//  PayProcessRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 14.05.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct PayProcessRequest {
    
    let accessToken: String
    let paymentId: String
    let sbId: String
    
}

extension PayProcessRequest {
    
    var requestParameters: [String: Any] {
        return [
            "paymentId": paymentId,
            "sbId": sbId
        ]
    }
    
}
