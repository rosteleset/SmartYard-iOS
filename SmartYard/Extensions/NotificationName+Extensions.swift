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
    static let addressAdded = Notification.Name("AddressAdded")
    static let badgeNumberUpdated = Notification.Name("BadgeNumberUpdated")
    static let newInboxMessageReceived = Notification.Name("NewInboxMessageReceived")
    static let addAddressFromSettings = Notification.Name("AddAddressFromSettings")
    static let userNameUpdated = Notification.Name("UserNameUpdated")
    static let chatRequested = Notification.Name("ChatRequested")
    
}

enum NotificationKeys {
    
    static let badgeNumberKey = "badgeNumberKey"
    static let contractNameKey = "contractNameKey"
    static let serviceTypeKey = "serviceTypeKey"
    static let serviceActionKey = "serviceActionKey"
    
}
