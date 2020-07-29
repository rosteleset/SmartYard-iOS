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
    static let addAddressFromSettings = Notification.Name("AddAddressFromSettings")
    static let userNameUpdated = Notification.Name("UserNameUpdated")
    static let chatRequested = Notification.Name("ChatRequested")
    static let onlineFullscreenModeClosed = Notification.Name("OnlineFullscreenModeClosed")
    static let archiveFullscreenModeClosed = Notification.Name("ArchiveFullscreenModeClosed")
    static let paymentCompleted = Notification.Name("PaymentCompleted")
    static let videoRequestedByCallKit = Notification.Name("VideoRequestedByCallKit")
    
    static let newInboxMessageReceived = Notification.Name("NewInboxMessageReceived")
    static let allInboxMessagesRead = Notification.Name("AllInboxMessagesRead")
    static let unreadInboxMessagesAvailable = Notification.Name("UnreadInboxMessagesAvailable")
    
    static let newChatMessageReceived = Notification.Name("NewChatMessageReceived")
    static let allChatMessagesRead = Notification.Name("AllChatMessagesRead")
    static let unreadChatMessagesAvailable = Notification.Name("UnreadChatMessagesAvailable")
    
    static let incomingCallForceLandscape = Notification.Name("IncomingCallForceLandscape")
    static let incomingCallForcePortrait = Notification.Name("IncomingCallForcePortrait")
    
}

enum NotificationKeys {
    
    static let badgeNumberKey = "badgeNumberKey"
    static let contractNameKey = "contractNameKey"
    static let serviceTypeKey = "serviceTypeKey"
    static let serviceActionKey = "serviceActionKey"
    
}
