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
        
        // MARK: При запуске приложения запрашиваем количество непрочитанных сообщений
        // Пуши - вещь ненадежная, чисто в теории нам мог не дойти пуш с актуальным badge
        
        appCoordinator.syncBadgeNumber()
        
        // MARK: При запуске приложения помечаем все сообщения как доставленные
        // То, что мы можем пометить одно и то же сообщение много раз - пофиг. Главное - пометить
        
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
        
        // MARK: Если в пуше пришел Badge - посылаем локальное уведомление, чтобы обновить Badge в таббаре
        
        if let aps = userInfo["aps"] as? [AnyHashable: Any],
            let badge = aps["badge"] as? Int {
            NotificationCenter.default.post(
                name: .badgeNumberUpdated,
                object: nil,
                userInfo: [NotificationKeys.badgeNumberKey: badge]
            )
        }
        
        // MARK: Если пришел входящий звонок - переходим на экран входящего звонка, но не показываем пуш
        
        if let callPayload = CallPayload(pushNotificationPayload: userInfo) {
            appCoordinator.processIncomingCallRequest(callPayload: callPayload)
            completionHandler([])
            return
        }
        
        // MARK: Если пришло inbox message - сразу же помечаем его как доставленное
        
        if let rawMessageType = userInfo["messageType"] as? String,
            let messageType = MessageType(rawValue: rawMessageType),
            messageType == .inbox,
            let messageId = userInfo["messageId"] as? String {
            appCoordinator.markMessagesAsDelivered(messageIds: [messageId])
            NotificationCenter.default.post(name: .newInboxMessageReceived, object: nil)
            
            if let newAddress = userInfo["newAddress"] as? String, newAddress == "t" {
                NotificationCenter.default.post(name: .addressAdded, object: nil)
            }
        }
        
        completionHandler([.alert, .badge, .sound])
    }
    
    // MARK: Чтобы при нажатии на пуш происходило какое-то действие
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // MARK: Если нажали на уведомление о входящем звонке - процессим запрос
        
        if let callPayload = CallPayload(
            pushNotificationPayload: response.notification.request.content.userInfo
        ) {
            appCoordinator.processIncomingCallRequest(callPayload: callPayload)
        }
        
        // MARK: Если нажали на inbox message - помечаем его как доставленное и переходим в уведомления
        // Если нажали на chat message - переходим в чат
        
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
