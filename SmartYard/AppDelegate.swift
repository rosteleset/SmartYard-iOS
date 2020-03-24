//
//  AppDelegate.swift
//  SmartYard
//
//  Created by admin on 28/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private lazy var mainWindow = UIWindow()
    
    private let appCoordinator = AppCoordinator()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureFirebase(for: application)
        
        appCoordinator.setRoot(for: mainWindow)
        appCoordinator.markAllMessagesAsDelivered()
        
        return true
    }

}

// MARK: Push Notifications

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("DEBUG / PUSH NOTIFICATIONS / Firebase registration token: \(fcmToken)")
    }
    
    private func configureFirebase(for application: UIApplication) {
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in })
        
        application.registerForRemoteNotifications()
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // MARK: Чтобы отображались пуши, если приложение в данный момент активно (в foreground)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        
        if let messageID = userInfo["gcm.message_id"] {
            print("DEBUG / PUSH NOTIFICATIONS / Message ID: \(messageID)")
        }
        
        print("DEBUG / PUSH NOTIFICATIONS / User Info: \(userInfo)")
        
        if let callPayload = CallPayload(pushNotificationPayload: userInfo) {
            appCoordinator.processIncomingCallRequest(callPayload: callPayload)
            completionHandler([])
            return
        }
        
        if let rawMessageType = userInfo["messageType"] as? String,
            let messageType = MessageType(rawValue: rawMessageType),
            messageType == .inbox,
            let messageId = userInfo["messageId"] as? String {
            appCoordinator.markMessagesAsDelivered(messageIds: [messageId])
        }
        
        completionHandler([.alert, .badge, .sound])
    }
    
    // MARK: Чтобы при нажатии на пуш происходило какое-то действие
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let callPayload = CallPayload(
            pushNotificationPayload: response.notification.request.content.userInfo
        ) {
            appCoordinator.processIncomingCallRequest(callPayload: callPayload)
        }
        
        if let rawMessageType = response.notification.request.content.userInfo["messageType"] as? String,
            let messageType = MessageType(rawValue: rawMessageType) {
            switch messageType {
            case .inbox: appCoordinator.openNotificationsTab()
            case .chat: appCoordinator.openChatTab()
            }
            
            if let messageId = response.notification.request.content.userInfo["messageId"] as? String,
                messageType == .inbox {
                appCoordinator.markMessagesAsDelivered(messageIds: [messageId])
            }
        }
        
        completionHandler()
    }
    
}
