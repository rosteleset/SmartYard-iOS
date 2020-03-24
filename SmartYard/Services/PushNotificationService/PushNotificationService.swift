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
    
    func registerForPushNotifications() -> Single<Void?> {
        guard let fcmToken = Messaging.messaging().fcmToken else {
            return .error(NSError.PushNotificationServiceError.fcmTokenMissing)
        }
        
        return apiWrapper.registerPushToken(pushToken: fcmToken, clientId: nil, type: .fcmRepeating)
    }
    
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

    func markMessagesAsDelivered(messageIds: [String]) {
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
    
    func getMessagesCountAndUpdateBadge() {
        apiWrapper.unreaded()
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { response in
                    UIApplication.shared.applicationIconBadgeNumber = response.count
                }
            )
            .disposed(by: disposeBag)
    }
    
    func resetMessagesCount() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
}
