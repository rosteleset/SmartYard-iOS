//
//  DeliveredRequest.swift
//  SmartYard
//
//  Created by admin on 24/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
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
