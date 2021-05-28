//
//  PlogRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 22.03.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//
import Foundation

struct PlogRequest {
    
    let accessToken: String
    let forceRefresh: Bool
    let flatId: String
    let fromDate: Date
}

extension PlogRequest {
    
    var requestParameters: [String: Any] {
        let params: [String: Any] = [
            "flatId": flatId,
            "day": fromDate.apiShortString
        ]
        
        return params
    }
    
}
