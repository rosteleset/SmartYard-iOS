//
//  DeliveredRequest.swift
//  SmartYard
//
//  Created by admin on 24/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct DeliveredRequest {
    
    let accessToken: String
    let messageId: String
    
}

extension DeliveredRequest {
    
    var requestParameters: [String: Any] {
        return ["messageId": messageId]
    }
    
}
