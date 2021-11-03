//
//  AccessRequest.swift
//  SmartYard
//
//  Created by admin on 16/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct AccessRequest {
    
    let accessToken: String
    let flatId: String
    
    let clientId: String?
    let guestPhone: String?
    let type: APIRoommateAccessType?
    let expire: Date?
    
}

extension AccessRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "flatId": flatId
        ]
        
        if let clientId = clientId {
            params["clientId"] = clientId
        }
        
        if let guestPhone = guestPhone {
            params["guestPhone"] = guestPhone
        }
        
        if let type = type {
            params["type"] = type.rawValue
        }
        
        if let expire = expire {
            params["expire"] = expire.apiString
        }
        
        return params
    }
    
}
