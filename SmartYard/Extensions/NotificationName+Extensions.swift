//
//  NotificationName+Extensions.swift
//  SmartYard
//
//  Created by admin on 20/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

enum NotificationKeys {
    
    static let badgeNumberKey = "badgeNumberKey"
    static let contractNameKey = "contractNameKey"
    static let serviceTypeKey = "serviceTypeKey"
    static let serviceActionKey = "serviceActionKey"
    
}

extension Notification.Name {
    
    static let addressDeleted = Notification.Name("AddressDeleted")
    static let addressAdded = Notification.Name("AddressAdded")
    static let addressNeedUpdate = Notification.Name("AddressNeedUpdate")
    static let updateCityCoordinate = Notification.Name("UpdateCityCoordinate")
    static let updateCameraOrder = Notification.Name("UpdateCameraOrder")
    static let stopAllCamerasPlaying = Notification.Name("StopAllCameraPlaying")

    static let addAddressFromSettings = Notification.Name("AddAddressFromSettings")
    static let userNameUpdated = Notification.Name("UserNameUpdated")
    static let authorizationCompleted = Notification.Name("AuthorizationCompleted")
    static let authorizationFailed = Notification.Name("AuthorizationFailed")
    static let chatRequested = Notification.Name("ChatRequested")
    static let chatwootRequested = Notification.Name("ChatwootRequested")
    static let onlineFullscreenModeClosed = Notification.Name("OnlineFullscreenModeClosed")
    static let archiveFullscreenModeClosed = Notification.Name("ArchiveFullscreenModeClosed")
    static let archiveFullscreenClipDownloadClosed = Notification.Name("ArchiveFullscreenClipDownloadClosed")
    static let paymentCompleted = Notification.Name("PaymentCompleted")
    static let videoRequestedByCallKit = Notification.Name("VideoRequestedByCallKit")
    static let answeredByCallKit = Notification.Name("AnsweredByCallKit")
    static let cityFullscreenModeClosed = Notification.Name("CityFullscreenModeClosed")

    static let newInboxMessageReceived = Notification.Name("NewInboxMessageReceived")
    static let allInboxMessagesRead = Notification.Name("AllInboxMessagesRead")
    static let unreadInboxMessagesAvailable = Notification.Name("UnreadInboxMessagesAvailable")
    static let updateInboxNotificationsSelect = Notification.Name("updateInboxNotificationsSelect")

    static let newChatMessageReceived = Notification.Name("NewChatMessageReceived")
    static let allChatMessagesRead = Notification.Name("AllChatMessagesRead")
    static let unreadChatMessagesAvailable = Notification.Name("UnreadChatMessagesAvailable")
    
    static let newChatwootMessageReceived = Notification.Name("NewChatwootMessageReceived")
    static let unreadChatwootMessagesAvailable = Notification.Name("UnreadChatwootMessagesAvailable")
    static let updateChatwootChat = Notification.Name("UpdateChatwootChat")
    static let updateChatwootChatSelect = Notification.Name("UpdateChatwootChatSelect")

    static let incomingCallForceLandscape = Notification.Name("IncomingCallForceLandscape")
    static let incomingCallForcePortrait = Notification.Name("IncomingCallForcePortrait")
    
    static let fullscreenArchiveForceLandscape = Notification.Name("FullscreenArchiveForceLandscape")
    static let fullscreenArchiveForcePortrait = Notification.Name("FullscreenArchiveForcePortrait")
    
    static let popupDimissed = Notification.Name("PopUpDimissed")
    
    static let updateFaces = Notification.Name("UpdateFaces")
    static let updateEvent = Notification.Name("UpdateEvent")
    
    static let refreshVisibleWebVC = Notification.Name("RefreshVisibleWebVC")
    static let updateOptions = Notification.Name("UpdateOptions")
    static let resendPushToJS = Notification.Name("ResendPushToJS")
    
    static let refreshPayCard = Notification.Name("RefreshPayCard")
    static let reconfigureGestures = Notification.Name("ReconfigureGestures")
}
