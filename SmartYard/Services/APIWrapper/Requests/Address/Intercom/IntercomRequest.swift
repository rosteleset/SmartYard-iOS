//
//  HourGuestAccessRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 21.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct IntercomRequest {
    
    let accessToken: String
    let forceRefresh: Bool
    let flatId: String
    let settings: APIIntercomSettings?
    
}

extension IntercomRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "flatId": flatId
        ]
        
        if let settings = settings {
            params["settings"] = settings.requestParameters
        }
        
        return params
    }
    
}
