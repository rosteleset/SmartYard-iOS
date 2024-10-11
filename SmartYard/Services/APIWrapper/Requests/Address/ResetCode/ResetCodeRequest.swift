//
//  ResetCodeRequest.swift
//  SmartYard
//
//  Created by admin on 25/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct ResetCodeRequest {
    
    let accessToken: String
    let flatId: String
    let domophoneId: String?
    
}

extension ResetCodeRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "flatId": flatId
        ]
        
        if let domophoneId = domophoneId {
            params["domophoneId"] = domophoneId
        }
        
        return params
    }
    
}
