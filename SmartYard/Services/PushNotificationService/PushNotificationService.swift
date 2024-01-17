//
//  PushNotificationService.swift
//  SmartYard
//
//  Created by admin on 18/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import FirebaseMessaging

private let ignoredCallIdsKey = "ignoredCallIds"

class PushNotificationService {
    
    private let apiWrapper: APIWrapper
    private let disposeBag = DisposeBag()
    
    private let userNotificationCenter = UNUserNotificationCenter.current()
    
    var ignoredCallIds: Set<String> {
        get {
            return UserDefaults.standard.object(Set<String>.self, with: ignoredCallIdsKey) ?? []
        }
        set {
            UserDefaults.standard.set(object: newValue, forKey: ignoredCallIdsKey)
        }
    }
    
    init(apiWrapper: APIWrapper) {
        self.apiWrapper = apiWrapper
    }
    
    func ignoreIncomingCall(withId callId: String) {
        var currentIgnoredCallIds = ignoredCallIds
        currentIgnoredCallIds.insert(callId)
        ignoredCallIds = currentIgnoredCallIds
    }
    
    func isCallIgnored(callId: String) -> Bool {
        return ignoredCallIds.contains(callId)
    }
    
    /// Сбрасывает InstanceId. Этакий способ гарантированно отписаться от уведомлений при разлогине
    func resetInstanceId() -> Single<Void?> {
        return Single.create { single in
            Messaging.messaging().deleteData { error in
                #if targetEnvironment(simulator)
                
                return single(.success(()))
                
                #else

                guard let error = error else {
                    single(.success(()))
                    return
                }
                
                let nsError = error as NSError
                
                if nsError.domain == "NSURLErrorDomain", nsError.code == -1009 {
                    single(.failure(NSError.PushNotificationServiceError.connectionRequired))
                } else {
                    single(.failure(error))
                }
                
                #endif
            }
            
            return Disposables.create()
        }
    }
    
    /// Подписка на уведомления. Если прокинуты оба токена, звонки будут идти через VoIP пуши
    func registerForPushNotifications(voipToken: String?) -> Single<Void?> {
        guard let fcmToken = Messaging.messaging().fcmToken else {
            return .error(NSError.PushNotificationServiceError.fcmTokenMissing)
        }
        
        print("DEBUG / REGISTER WITH VOIP TOKEN \(String(describing: voipToken))")
        
        return apiWrapper.registerPushToken(
            pushToken: fcmToken,
            voipToken: voipToken,
            clientId: nil,
            type: .fcmRepeating
        )
    }
    
    /// Помечает все inbox message, которые сейчас есть в NotificationCenter, как доставленные (чтобы бэк не присылал их повторно)
    func markAllMessagesAsDelivered() {
        userNotificationCenter.getDeliveredNotifications { [weak self] notifications in
            let messageIds: [String] = notifications.compactMap { notification in
                guard let rawMessageType = notification.request.content.userInfo["messageType"] as? String,
                    let messageType = MessageType(rawValue: rawMessageType),
                    messageType == .inbox,
                    let messageId = notification.request.content.userInfo["messageId"] as? String else {
                    return nil
                }
                
                return messageId
            }
            
            DispatchQueue.main.async {
                self?.markMessagesAsDelivered(messageIds: messageIds)
            }
        }
    }

    /// Помечает inbox message с заданными messageId как доставленные (чтобы бэк не присылал их повторно)
    func markMessagesAsDelivered(messageIds: [String]) {
        // MARK: сейчас я не совсем представляю, как мне гарантировать отправку маркера на сервер
        // Сколько раз ретраить запрос и т.д.
        // Поэтому я просто создаю запросы на каждый пуш и выполняю их. Без разницы, какой будет результат
        
        let queries = messageIds.map { messageId in
            apiWrapper.delivered(messageId: messageId)
                .asDriver(onErrorJustReturn: nil)
                .map { (response: Void?) -> (String, Bool) in
                    (messageId, response != nil)
                }
        }
        
        Driver
            .concat(queries)
            .drive(
                onNext: { messageId, isMarked in
                    print("Message \(messageId) delivery state is: \(isMarked)")
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// Удаляет все уведомления с заданным типом действия из Notification Center
    func deleteAllDeliveredNotifications(withActionType neededAction: MessageType) {
        userNotificationCenter.getDeliveredNotifications { [weak self] notifications in
            let notificationIds: [String] = notifications.compactMap { notification in
                guard let rawAction = notification.request.content.userInfo["action"] as? String,
                    let action = MessageType(rawValue: rawAction),
                    action == neededAction else {
                    return nil
                }
                
                return notification.request.identifier
            }
            
            self?.userNotificationCenter.removeDeliveredNotifications(withIdentifiers: notificationIds)
        }
    }
    
    /// Получает с сервера количество непрочитанных сообщений и обновляет Badge
    func synchronizeBadgeCount() {
        apiWrapper.unreaded()
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { response in
                    UIApplication.shared.applicationIconBadgeNumber = response.count + response.chat
                    
                    NotificationCenter.default.post(
                        // swiftlint:disable:next empty_count
                        name: response.count == 0 ? .allInboxMessagesRead : .unreadInboxMessagesAvailable,
                        object: nil
                    )
                    
                    NotificationCenter.default.post(
                        name: response.chat == 0 ? .allChatMessagesRead : .unreadChatMessagesAvailable,
                        object: nil
                    )
                }
            )
            .disposed(by: disposeBag)
    }
    
}
