//
//  ConfirmCodeRequest.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

struct CheckPhoneRequest {
    
    let userPhone: String
    let deviceToken: String
    
}

extension CheckPhoneRequest {
    
    var requestParameters: [String: Any] {
        return [
            "userPhone": userPhone,
            "deviceToken": deviceToken
        ]
    }
    
}
