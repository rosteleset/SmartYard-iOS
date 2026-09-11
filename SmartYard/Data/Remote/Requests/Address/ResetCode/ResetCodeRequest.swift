//
//  ResetCodeRequest.swift
//  SmartYard
//
//  Created by admin on 25/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

struct ResetCodeRequest {
    
    let accessToken: String
    let flatId: String
    
}

extension ResetCodeRequest {
    
    var requestParameters: [String: Any] {
        return [
            "flatId": flatId
        ]
    }
    
}
