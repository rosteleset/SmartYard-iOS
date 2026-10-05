//
//  UNAuthorizationType+Extensions.swift
//  SmartYard
//
//  Created by admin on 18/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import UserNotifications

extension UNAuthorizationStatus {
    
    var hasAccess: Bool {
        var allowedStatuses: [UNAuthorizationStatus] = [.authorized]
        
        allowedStatuses.append(.provisional)
        
        return allowedStatuses.contains(self)
    }
    
}
