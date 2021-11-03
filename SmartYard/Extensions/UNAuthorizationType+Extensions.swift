//
//  UNAuthorizationType+Extensions.swift
//  SmartYard
//
//  Created by admin on 18/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UserNotifications

extension UNAuthorizationStatus {
    
    var hasAccess: Bool {
        var allowedStatuses: [UNAuthorizationStatus] = [.authorized]
        
        if #available(iOS 12.0, *) {
            allowedStatuses.append(.provisional)
        }
        
        return allowedStatuses.contains(self)
    }
    
}
