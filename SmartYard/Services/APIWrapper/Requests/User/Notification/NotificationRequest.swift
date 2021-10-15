//
//  NotificationRequest.swift
//  SmartYard
//
//  Created by admin on 30/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct NotificationRequest {
    
    let accessToken: String
    let money: Bool?
    let enable: Bool?
    
}

extension NotificationRequest {
    
    var requestParameters: [String: Any] {
        var params = [String: Any]()
        
        if let money = money {
            params["money"] = money ? "t" : "f"
        }
        
        if let enable = enable {
            params["enable"] = enable ? "t" : "f"
        }
        
        return params
    }
    
}
