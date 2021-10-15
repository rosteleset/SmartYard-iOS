//
//  AppDelegate.swift
//  SmartYard
//
//  Created by admin on 28/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import YandexMobileMetrica
import PushKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let mainWindow: UIWindow
    private let appCoordinator: AppCoordinator
    
    override init() {
        mainWindow = UIWindow()
        appCoordinator = AppCoordinator(mainWindow: mainWindow)
        
        super.init()
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureFirebase(for: application)
        
        configureVoIPNotifications()
        
        if let yandexConfig = YMMYandexMetricaConfiguration(apiKey: Constants.yandexApiKey) {
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
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        switch userActivity.activityType {
        case "INStartVideoCallIntent":
            NotificationCenter.default.post(name: .videoRequestedByCallKit, object: nil)
        case NSUserActivityTypeBrowsingWeb:
            // Обработка deeplinks
            guard
                let incomingURL = userActivity.webpageURL,
                let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
                return false
            }
            
            // обрабатываем только url вида https://demo.lanta.me/0123456789 для подтверждения адреса
            if components.host == "demo.lanta.me",
               components.scheme == "https",
               let path = components.path,
               path.matches(pattern: "/[0-9]{10}") {
                    appCoordinator.trigger(.registerQRCode(code: incomingURL.absoluteString))
            } else
            // в противном случае даём OS обработать это событие самостоятельно
            {
                return false
            }
            
        default:
            break
        }
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        guard let topVc = window?.rootViewController?.topViewController else {
            return .portrait
        }
        
        if topVc is FullscreenPlayerViewController,
            !topVc.isBeingDismissed,
            !topVc.isBeingPresented {
            return .allButUpsideDown
        } else if topVc is IncomingCallLandscapeViewController,
            !topVc.isBeingDismissed {
            return .landscape
        } else {
            return .portrait
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        UserDefaults.standard.synchronize()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        NotificationCenter.default.post(name: .applicationDidEnterBackground, object: nil)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationCenter.default.post(name: .applicationDidEnterForeground, object: nil)
    }

}

// MARK: Push Notifications

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("DEBUG / PUSH NOTIFICATIONS / Firebase registration token: \(String(describing: fcmToken))")
        
        appCoordinator.updateFCMToken()
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
        
        print("DEBUG / PUSH NOTIFICATIONS / User Info: \(userInfo)")
        
        // MARK: если в push-сообщении есть адрес backend-сервера, то обновляем его.
        if let backendURL = userInfo["baseUrl"] as? String {
            appCoordinator.updateBackendURL(backendURL)
        }
        
        // MARK: Если пришел входящий звонок - переходим на экран входящего звонка, но не показываем пуш
        
        if let callPayload = CallPayload(pushNotificationPayload: userInfo) {
            appCoordinator.processIncomingCallRequest(callPayload: callPayload, useCallKit: false)
            completionHandler([])
            return
        }
        
        // MARK: Если есть messageId - помечаем сообщение как доставленное
        
        if let messageId = userInfo["messageId"] as? String {
            appCoordinator.markMessagesAsDelivered(messageIds: [messageId])
        }
        
        // MARK: Проверяем, есть ли у уведомления тип действия. Если нет - то в принципе ничего не делаем
        
        guard let rawAction = userInfo["action"] as? String,
            let action = MessageType(rawValue: rawAction) else {
            completionHandler([.alert, .badge, .sound])
            return
        }
        
        // MARK: Если пришло уведомление о новом уведомлении в списке - отправляем .newInboxMessageReceived
        // Это вызовет показ баджа в табе "Уведомления" и обновление списка уведомлений
        
        if action == .inbox || action == .videoReady {
            NotificationCenter.default.post(name: .newInboxMessageReceived, object: nil)
            NotificationCenter.default.post(name: .unreadInboxMessagesAvailable, object: nil)
        }
        
        // MARK: Если пришло уведомление о новом сообщении чата - отправляем .newInboxMessageReceived
        // Это вызовет показ баджа в табе "Чат" и обновление сообщений чата
        
        if action == .chat {
            NotificationCenter.default.post(name: .newChatMessageReceived, object: nil)
            NotificationCenter.default.post(name: .unreadChatMessagesAvailable, object: nil)
            
            // MARK: Если уже находимся на вкладке "Чат", то не показываем пуш
            
            if appCoordinator.selectedTabPresentable?.router(for: ChatRoute.main) != nil {
                completionHandler([])
                return
            }
        }
        
        // MARK: Если пришло уведомление о добавленном адресе - отправляем .addressAdded
        // Это вызовет перезагрузку данных в табах "Адреса" и "Настройки"
        
        if action == .newAddress {
            NotificationCenter.default.post(name: .addressAdded, object: nil)
        }
        
        // MARK: Если пришло уведомление об успешном платеже - отправляем .paymentCompleted
        // Это вызовет обновление данных в табе "Оплатить"
        
        if action == .paySuccess {
            NotificationCenter.default.post(name: .paymentCompleted, object: nil)
        }
        
        completionHandler([.alert, .badge, .sound])
    }
    
    // MARK: Чтобы при нажатии на пуш происходило какое-то действие
    // (в т.ч. обработка  push, когда приложение в background)
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // MARK: если в push-сообщении есть адрес backend-сервера, то обновляем его.
        if let backendURL = userInfo["baseUrl"] as? String {
            appCoordinator.updateBackendURL(backendURL)
        }
        
        // MARK: Если нажали на уведомление о входящем звонке - процессим запрос
        
        if let callPayload = CallPayload(
            pushNotificationPayload: userInfo
        ) {
            appCoordinator.processIncomingCallRequest(callPayload: callPayload, useCallKit: false)
            completionHandler()
            return
        }
        
        // MARK: Если есть messageId - помечаем сообщение как доставленное. Лучше два раза, чем ни разу
        
        if let messageId = userInfo["messageId"] as? String {
            appCoordinator.markMessagesAsDelivered(messageIds: [messageId])
        }
        
        // MARK: Если в уведомлении нет никакого действия, то ничего не делаем
        
        guard let rawAction = userInfo["action"] as? String,
            let action = MessageType(rawValue: rawAction) else {
            completionHandler()
            return
        }
        
        // MARK: Переход в конкретный таб при нажатии на уведомление
        
        switch action {
        case .inbox, .newAddress, .paySuccess, .payError, .videoReady:
            appCoordinator.openNotificationsTab()
        case .chat:
            appCoordinator.openChatTab()
        }
        
        // MARK: Если нажали на уведомление о добавленном адресе - отправляем .addressAdded
        // Это вызовет перезагрузку данных в табах "Адреса" и "Настройки"
        // Сделано это вроде для того, чтобы если приложение ушло в бекграунд, данные обновились при нажатии
        
        if action == .newAddress {
            NotificationCenter.default.post(name: .addressAdded, object: nil)
        }
        
        // MARK: Для платежей - аналогично
        
        if action == .paySuccess {
            NotificationCenter.default.post(name: .paymentCompleted, object: nil)
        }
        
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
        
        print("DEBUG / GOT NEW TOKEN \(token)")
        
        appCoordinator.setVoipToken(token)
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
        
        // если в push-сообщении есть адрес backend-сервера, то обновляем его.
        if let backendURL = data["baseUrl"] as? String {
            appCoordinator.updateBackendURL(backendURL)
        }
        
        appCoordinator.processIncomingCallRequest(callPayload: callPayload, useCallKit: true)
    }
    
    private func configureVoIPNotifications() {
        let registry = PKPushRegistry(queue: DispatchQueue.main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
    }
    
}

public let imagesCache = NSCache<NSString, UIImage>()
