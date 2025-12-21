//
//  ConfirmCodeRequest.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct ConfirmCodeRequest {
    
    let userPhone: String
    let smsCode: String
    let deviceToken: String
    
}

extension ConfirmCodeRequest {
    
    var requestParameters: [String: Any] {
        return [
            "userPhone": userPhone,
            "smsCode": smsCode,
            "deviceToken": deviceToken
        ]
    }
    
}
