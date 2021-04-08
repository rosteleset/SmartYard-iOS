//
//  PlogRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 22.03.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//
import Foundation

struct PlogDaysRequest {
    
    let accessToken: String
    let flatId: String
}

extension PlogDaysRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "flatId": flatId
        ]
        
        return params
    }
    
}
