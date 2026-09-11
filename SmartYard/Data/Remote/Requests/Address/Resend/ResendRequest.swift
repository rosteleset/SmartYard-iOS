//
//  ResendRequest.swift
//  SmartYard
//
//  Created by admin on 17/03/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

struct ResendRequest {
    
    let accessToken: String
    let flatId: String
    let guestPhone: String
    
}

extension ResendRequest {
    
    var requestParameters: [String: Any] {
        return [
            "flatId": flatId,
            "guestPhone": guestPhone
        ]
    }
    
}
