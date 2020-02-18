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
    
    func updatePushNotificationsState(forClientId clientId: String, newState: TokenState) -> Single<Void?> {
        guard let fcmToken = Messaging.messaging().fcmToken else {
            return .error(NSError.PushNotificationServiceError.fcmTokenMissing)
        }
        
        return apiWrapper.updateTokenState(pushToken: fcmToken, clientId: clientId, newState: newState)
            .retryWhen { obsError -> Observable<Void?> in
                obsError.flatMap { [weak self] error -> Single<Void?> in
                    let nsError = error as NSError
                    
                    guard let self = self else {
                        return .error(NSError.GenericError.selfIsDeadError)
                    }
                    
                    guard nsError.code == 404 else {
                        return .error(error)
                    }
                    
                    return self.apiWrapper.registerToken(pushToken: fcmToken, clientId: clientId, type: .fcm)
                }
            }
    }
    
    func getPushNotificationsState(forClientId clientId: String) -> Single<TokenState?> {
        guard let fcmToken = Messaging.messaging().fcmToken else {
            return .error(NSError.PushNotificationServiceError.fcmTokenMissing)
        }
        
        return apiWrapper.checkTokenState(pushToken: fcmToken, clientId: clientId)
            .map { $0?.state }
            .retryWhen { obsError -> Observable<Void?> in
                obsError.flatMap { [weak self] error -> Single<Void?> in
                    let nsError = error as NSError
                    
                    guard let self = self else {
                        return .error(NSError.GenericError.selfIsDeadError)
                    }
                    
                    guard nsError.code == 404 else {
                        return .error(error)
                    }
                    
                    return self.apiWrapper.registerToken(pushToken: fcmToken, clientId: clientId, type: .fcm)
                }
            }
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
    
}
