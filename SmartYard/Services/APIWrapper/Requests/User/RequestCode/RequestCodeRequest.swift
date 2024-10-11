//
//  RequestCodeRequest.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct RequestCodeRequest {
    
    let userPhone: String
    let type: String?
    let pushToken: String?
    
}

extension RequestCodeRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "userPhone": userPhone
        ]

        if let type = type {
            params["type"] = type
        }
        
        if let pushToken = pushToken {
            params["pushToken"] = pushToken
        }
        
        return params
    }
    
}
