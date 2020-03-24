//
//  PushNotificationService.swift
//  SmartYard
//
//  Created by admin on 18/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import Firebase

class PushNotificationService {
    
    private let apiWrapper: APIWrapper
    private let disposeBag = DisposeBag()
    
    private let userNotificationCenter = UNUserNotificationCenter.current()
    
    init(apiWrapper: APIWrapper) {
        self.apiWrapper = apiWrapper
    }
    
    /// Сбрасывает InstanceId. Этакий способ гарантированно отписаться от уведомлений при разлогине
    func resetInstanceId() -> Single<Void?> {
        return Single.create { single in
            InstanceID.instanceID().deleteID { error in
                guard let error = error else {
                    single(.success(()))
                    return
                }
                
                single(.error(error))
            }
            
            return Disposables.create()
        }
    }
    
    /// Подписка на уведомления
    func registerForPushNotifications() -> Single<Void?> {
        guard let fcmToken = Messaging.messaging().fcmToken else {
            return .error(NSError.PushNotificationServiceError.fcmTokenMissing)
        }
        
        return apiWrapper.registerPushToken(pushToken: fcmToken, clientId: nil, type: .fcmRepeating)
    }
    
    /// Помечает все inbox message, которые сейчас есть в NotificationCenter, как доставленные
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

    /// Помечает inbox message с заданными messageId как доставленные
    func markMessagesAsDelivered(messageIds: [String]) {
        // MARK: сейчас я не совсем представляю, как мне гарантировать отправку маркера на сервер
        // Сколько раз ретраить запрос и т.д.
        // Поэтому я просто создаю запросы на каждый пуш и выполняю их. Без разницы, какой будет результат
        
        let queries = messageIds.map { messageId in
            apiWrapper.delivered(messageId: messageId)
                .asDriver(onErrorJustReturn: nil)
        }
        
        Driver
            .concat(queries)
            .drive(
                onNext: { _ in
                    print("Probably marked all messages as delivered")
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// Удаляет все inbox message из NotificationCenter и сбрасывает Badge
    func markAllMessagesAsRead() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        NotificationCenter.default.post(
            name: .badgeNumberUpdated,
            object: nil,
            userInfo: [NotificationKeys.badgeNumberKey: 0]
        )
        
        userNotificationCenter.getDeliveredNotifications { [weak self] notifications in
            let notificationIds: [String] = notifications.compactMap { notification in
                guard let rawMessageType = notification.request.content.userInfo["messageType"] as? String,
                    let messageType = MessageType(rawValue: rawMessageType),
                    messageType == .inbox else {
                        return nil
                }
                
                return notification.request.identifier
            }
            
            self?.userNotificationCenter.removeDeliveredNotifications(withIdentifiers: notificationIds)
        }
    }
    
    /// Получает с сервера количество непрочитанных сообщений и обновляет Badge
    func getMessagesCountAndUpdateBadge() {
        apiWrapper.unreaded()
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { response in
                    UIApplication.shared.applicationIconBadgeNumber = response.count
                    
                    NotificationCenter.default.post(
                        name: .badgeNumberUpdated,
                        object: nil,
                        userInfo: [NotificationKeys.badgeNumberKey: response.count]
                    )
                }
            )
            .disposed(by: disposeBag)
    }
    
}
