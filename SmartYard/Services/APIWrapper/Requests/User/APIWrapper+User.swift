//
//  APIWrapper+User.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension APIWrapper {
    
    func addMyPhone(login: String, password: String, comment: String?, useForNotifications: Bool?) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = AddMyPhoneRequest(
            accessToken: accessToken,
            login: login,
            password: password,
            comment: comment,
            useForNotifications: useForNotifications
        )
        
        return provider.rx
            .request(.addMyPhone(request: request))
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func requestCode(userPhone: String) -> Single<Void?> {
        let request = RequestCodeRequest(userPhone: userPhone)
        
        return provider.rx
            .request(.requestCode(request: request))
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func registerPushToken(pushToken: String, clientId: String?, type: TokenType) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RegisterPushTokenRequest(
            accessToken: accessToken,
            pushToken: pushToken,
            clientId: clientId,
            type: type
        )
        
        return provider.rx
            .request(.registerPushToken(request: request))
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func confirmCode(userPhone: String, smsCode: String) -> Single<ConfirmCodeResponseData?> {
        guard accessService.accessToken == nil else {
            return .error(NSError.APIWrapperError.alreadyLoggedInError)
        }
        
        let request = ConfirmCodeRequest(userPhone: userPhone, smsCode: smsCode)
        
        return provider.rx
            .request(.confirmCode(request: request))
            .mapAsDefaultResponse()
    }
    
    func getPaymentsList() -> Single<GetPaymentsListResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetPaymentsListRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.getPaymentsList(request: request))
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func sendName(name: String, patronymic: String?) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = SendNameRequest(accessToken: accessToken, name: name, patronymic: patronymic)
        
        return provider.rx
            .request(.sendName(request: request))
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func restore(contractNum: String?, contactId: String?, code: String?) -> Single<RestoreRequestResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        guard let contractNum = contractNum else {
            return .error(NSError.APIWrapperError.contractNumberMissingError)
        }
        
        let request = RestoreRequest(
            accessToken: accessToken,
            contract: contractNum,
            contactId: contactId,
            code: code,
            comment: nil,
            notification: nil
        )
        
        return provider.rx.request(.restore(request: request))
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getCurrentNotificationState() -> Single<NotificationResponseData?> {
        return notification(money: nil, enable: nil)
    }
    
    func setNotificationMoneyState(isActive: Bool) -> Single<NotificationResponseData?> {
        return notification(money: isActive, enable: nil)
    }
    
    func setNotificationEnableState(isEnabled: Bool) -> Single<NotificationResponseData?> {
        return notification(money: nil, enable: isEnabled)
    }
    
    func notification(money: Bool?, enable: Bool?) -> Single<NotificationResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = NotificationRequest(accessToken: accessToken, money: money, enable: enable)
        
        return provider.rx
            .request(.notification(request: request))
            .mapAsDefaultResponse()
    }
    
}
