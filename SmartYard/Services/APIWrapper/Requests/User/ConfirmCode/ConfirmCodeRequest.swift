//
//  ConfirmCodeRequest.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct ConfirmCodeRequest {
    
    let userPhone: String
    let smsCode: String?
    let type: String?
    let requestId: String?
    
}

extension ConfirmCodeRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "userPhone": userPhone
        ]

        if let smsCode = smsCode {
            params["smsCode"] = smsCode
        }
        
        if let requestId = requestId {
            params["requestId"] = requestId
            params["type"] = "push"
        }
        
        return params
    }
    
}
