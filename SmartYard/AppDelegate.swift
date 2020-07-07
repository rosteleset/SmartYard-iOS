//
//  AppDelegate.swift
//  SmartYard
//
//  Created by admin on 28/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import Firebase
import YandexMobileMetrica
import PushKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private lazy var mainWindow = UIWindow()
    
    private let appCoordinator = AppCoordinator()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureFirebase(for: application)
        
        configureVoIPNotifications()
        
        if let yandexConfig = YMMYandexMetricaConfiguration(apiKey: "686bcc1e-69e5-4412-8d54-3e11e362624a") {
            YMMYandexMetrica.activate(with: yandexConfig)
        } else {
            print("Couldn't activate YMM")
        }
        
        appCoordinator.setRoot(for: mainWindow)
        
        // MARK: При запуске приложения запрашиваем количество непрочитанных сообщений
        // Пуши - вещь ненадежная, чисто в теории нам мог не дойти пуш с актуальным badge
        
        appCoordinator.syncBadgeNumber()
        
        // MARK: При запуске приложения помечаем все сообщения как доставленные
        // То, что мы можем пометить одно и то же сообщение много раз - пофиг. Главное - пометить
        
        appCoordinator.markAllMessagesAsDelivered()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        if let topVc = window?.rootViewController?.topViewController,
            topVc is FullscreenPlayerViewController,
            !topVc.isBeingDismissed,
            !topVc.isBeingPresented {
            return .allButUpsideDown
        } else {
            return .portrait
        }
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
            appCoordinator.processIncomingCallRequest(callPayload: callPayload, useCallKit: false)
            completionHandler([])
            return
        }
        
        // MARK: Если есть действие - обрабатываем его
        
        if let rawMessageType = userInfo["action"] as? String,
            let messageType = MessageType(rawValue: rawMessageType) {
            // MARK: Если есть messageId - помечаем сообщение как доставленное и обновляем таб "Уведомления"
            
            if let messageId = userInfo["messageId"] as? String {
                appCoordinator.markMessagesAsDelivered(messageIds: [messageId])
                NotificationCenter.default.post(name: .newInboxMessageReceived, object: nil)
            }
            
            // MARK: Если пришло уведомление о добавленном адресе - отправляем .addressAdded
            // Это вызовет перезагрузку данных в табах "Адреса" и "Настройки"
            
            if messageType == .newAddress {
                NotificationCenter.default.post(name: .addressAdded, object: nil)
            }
            
            if messageType == .paySuccess {
                NotificationCenter.default.post(name: .paymentCompleted, object: nil)
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
            appCoordinator.processIncomingCallRequest(callPayload: callPayload, useCallKit: false)
        }
        
        // MARK: Если в уведомлении нет никакого действия, то ничего не делаем
        
        guard let rawMessageType = response.notification.request.content.userInfo["action"] as? String,
            let messageType = MessageType(rawValue: rawMessageType) else {
            completionHandler()
            return
        }
        
        // MARK: Если есть messageId - помечаем сообщение как доставленное
        
        if let messageId = response.notification.request.content.userInfo["messageId"] as? String {
            appCoordinator.markMessagesAsDelivered(messageIds: [messageId])
        }
        
        // MARK: Переход в конкретный таб при нажатии на уведомление
        
        switch messageType {
        case .inbox, .newAddress, .paySuccess, .payError, .videoReady:
            appCoordinator.openNotificationsTab()
        case .chat:
            appCoordinator.openChatTab()
        }
        
        // MARK: Если нажали на уведомление о добавленном адресе - отправляем .addressAdded
        // Это вызовет перезагрузку данных в табах "Адреса" и "Настройки"
        // Сделано это вроде для того, чтобы если приложение ушло в бекграунд, данные обновились при нажатии
        
        if messageType == .newAddress {
            NotificationCenter.default.post(name: .addressAdded, object: nil)
        }
        
        if messageType == .paySuccess {
            NotificationCenter.default.post(name: .paymentCompleted, object: nil)
        }
        
        // MARK: Завершение работы
        
        completionHandler()
    }
    
}

// MARK: VoIP Notifications

extension AppDelegate: PKPushRegistryDelegate {
    
    func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        let token = pushCredentials.token
            .map { String(format: "%02.2hhx", $0) }
            .joined()
        
        print(token)
    }
    
    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        print("DEBUG / VOIP NOTIFICATIONS / Payload: \(payload.dictionaryPayload)")
        
        guard let data = payload.dictionaryPayload["data"] as? [AnyHashable: Any],
            let callPayload = CallPayload(pushNotificationPayload: data) else {
            appCoordinator.reportInvalidCall()
            completion()
            return
        }
        
        appCoordinator.processIncomingCallRequest(callPayload: callPayload, useCallKit: true)
    }
    
    private func configureVoIPNotifications() {
        let registry = PKPushRegistry(queue: DispatchQueue.main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
    }
    
}
