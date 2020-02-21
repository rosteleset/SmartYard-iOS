//
//  HourGuestAccessRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 21.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct HourGuestAccessRequest {
    
    let flatId: String
    let settings: APIIntercomSettings
    
}

extension HourGuestAccessRequest {
    
    var requestParameters: [String: Any] {
        return [
            "flatId": flatId,
            "settings": settings
        ]
    }
    
}
