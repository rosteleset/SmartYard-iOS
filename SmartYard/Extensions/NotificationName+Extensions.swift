//
//  NotificationName+Extensions.swift
//  SmartYard
//
//  Created by admin on 20/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

extension Notification.Name {
    
    static let addressDeleted = Notification.Name("AddressDeleted")
    static let badgeNumberUpdated = Notification.Name("BadgeNumberUpdated")
    
}

enum NotificationKeys {
    
    static let badgeNumberKey = "badgeNumberKey"
    
}
