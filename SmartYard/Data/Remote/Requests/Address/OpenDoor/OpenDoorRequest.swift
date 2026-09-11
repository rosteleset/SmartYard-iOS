//
//  OpenDoorRequest.swift
//  SmartYard
//
//  Created by admin on 18/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

struct OpenDoorRequest {
    
    let accessToken: String
    let domophoneId: String
    let doorId: Int?
    
}

extension OpenDoorRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "domophoneId": domophoneId
        ]
        
        if let doorId = doorId {
            params["doorId"] = doorId
        }
        
        return params
    }
    
}
