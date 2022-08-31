//
//  APIWrapper+User.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension APIWrapper {
    func getProvidersList() -> Single<APIProvidersListResult?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        return provider.rx
            .request(.getProvidersList, callbackQueue: .global(qos: .background))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func checkAppVersion() -> Single<APIAppVersionCheckResult?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = AppVersionRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.appVersion(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func addMyPhone(login: String, password: String, comment: String?, useForNotifications: Bool?) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
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
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func requestCode(userPhone: String) -> Single<RequestCodeResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        let request = RequestCodeRequest(userPhone: userPhone)
        
        return provider.rx
            .request(.requestCode(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func registerPushToken(
        pushToken: String,
        voipToken: String?,
        clientId: String?,
        type: TokenType
    ) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        #if DEBUG
        let production = false
        #elseif RELEASE
        let production = true
        #endif
        
        let request = RegisterPushTokenRequest(
            accessToken: accessToken,
            pushToken: pushToken,
            voipToken: voipToken,
            clientId: clientId,
            production: production,
            type: type
        )
        
        return provider.rx
            .request(.registerPushToken(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func confirmCode(userPhone: String, smsCode: String) -> Single<ConfirmCodeResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard accessService.accessToken == nil else {
            return .error(NSError.APIWrapperError.alreadyLoggedInError)
        }
        
        let request = ConfirmCodeRequest(userPhone: userPhone, smsCode: smsCode)
        
        return provider.rx
            .request(.confirmCode(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func checkPhone(userPhone: String) -> Single<CheckPhoneResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard accessService.accessToken == nil else {
            return .error(NSError.APIWrapperError.alreadyLoggedInError)
        }
        
        let request = CheckPhoneRequest(userPhone: userPhone)
        
        return provider.rx
            .request(.checkPhone(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func getPaymentsList(forceRefresh: Bool = false) -> Single<GetPaymentsListResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let forceRefresh = forceUpdatePayments || forceRefresh
        forceUpdatePayments = false
        
        let request = GetPaymentsListRequest(accessToken: accessToken, forceRefresh: forceRefresh)
        
        return provider.rx
            .request(.getPaymentsList(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func sendName(name: String, patronymic: String?) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = SendNameRequest(accessToken: accessToken, name: name, patronymic: patronymic)
        
        return provider.rx
            .request(.sendName(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func restore(contractNum: String?, contactId: String?, code: String?) -> Single<RestoreRequestResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
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
        
        return provider.rx
            .request(.restore(request: request))
            .convertNoConnectionError()
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
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = NotificationRequest(accessToken: accessToken, money: money, enable: enable)
        
        return provider.rx
            .request(.notification(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
}
