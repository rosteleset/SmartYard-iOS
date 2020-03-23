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
            .filterSuccessfulCodes()
            .map { _ in }
    }
    
    func requestCode(userPhone: String) -> Single<Void?> {
        let request = RequestCodeRequest(userPhone: userPhone)
        
        return provider.rx
            .request(.requestCode(request: request))
            .filterSuccessfulCodes()
            .map { _ in }
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
            .filterSuccessfulCodes()
            .map { _ in }
    }
    
    func confirmCode(userPhone: String, smsCode: String) -> Single<ConfirmCodeResponseData?> {
        guard accessService.accessToken == nil else {
            return .error(NSError.APIWrapperError.alreadyLoggedInError)
        }
        
        let request = ConfirmCodeRequest(userPhone: userPhone, smsCode: smsCode)
        
        return provider.rx
            .request(.confirmCode(request: request))
            .filterSuccessfulCodes()
            .map(BaseAPIResponse<ConfirmCodeResponseData>.self)
            .flatMap { response in
                guard let data = response.data else {
                    return .error(NSError.APIWrapperError.noDataError)
                }
                
                return .just(data)
            }
    }
    
    func getPaymentsList() -> Single<GetPaymentsListResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetPaymentsListRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.getPaymentsList(request: request))
            .filterSuccessfulCodes()
            .map(BaseAPIResponse<GetPaymentsListResponseData>.self)
            .flatMap { response in
                if let data = response.data {
                    return .just(data)
                } else if response.code == 204 {
                    return .just([])
                } else {
                    return .error(NSError.APIWrapperError.noDataError)
                }
            }
    }
    
    func sendName(name: String, patronymic: String?) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = SendNameRequest(accessToken: accessToken, name: name, patronymic: patronymic)
        
        return provider.rx
            .request(.sendName(request: request))
            .filterSuccessfulCodes()
            .map { _ in }
    }
    
}
