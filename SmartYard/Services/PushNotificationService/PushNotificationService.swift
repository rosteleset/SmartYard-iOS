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
        
        return apiWrapper.registerPushToken(pushToken: fcmToken, clientId: nil, type: .fcm)
    }
    
}
