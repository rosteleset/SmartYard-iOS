//
//  APIWrapper+Payment.swift
//  SmartYard
//
//  Created by Mad Brains on 14.05.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension APIWrapper {
    
    func payPrepare(clientId: String, amount: String) -> Single<PayPrepareResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = PayPrepareRequest(accessToken: accessToken, clientId: clientId, amount: amount)
        
        return provider.rx
            .request(.payPrepare(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func payProcess(paymentId: String, sbId: String) -> Single<PayProcessResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = PayProcessRequest(accessToken: accessToken, paymentId: paymentId, sbId: sbId)
        
        return provider.rx
            .request(.payProcess(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func sberbankPayProcess(merchant: String, orderNumber: String, paymentToken: String) -> Single<SberbankPayProcessResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        let request = SberbankPayProcessRequest(
            merchant: merchant,
            orderNumber: orderNumber,
            paymentToken: paymentToken
        )

        print(request)
        
        return provider.rx
            .request(.sberbankPayProcess(request: request))
            .convertNoConnectionError()
            .mapAsSberbankResponse()
    }
    
    func sberbankRegisterProcess(orderNumber: String, amount: String) -> Single<SberbankRegisterData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        let request = SberbankRegisterRequest(
            userName: Constants.sberbankAPILogin,
            password: Constants.sberbankAPIPassword,
            orderNumber: orderNumber,
            amount: amount,
            returnUrl: Constants.sberbankSuccessReturnURL,
            failUrl: Constants.sberbankFailureReturnURL
        )

        print(request)
        
        return provider.rx
            .request(.sberbankRegister(request: request))
            .convertNoConnectionError()
            .flatMap { response in
                // MARK: Если вернулся успешный код - пытаемся замапить реквест
                if 200...299 ~= response.statusCode {
                    do {
                        let data = try response.map(SberbankRegisterData.self)
                        
                        return .just(data)
                    } catch {
                        return .error(NSError.APIWrapperError.baseResponseMappingError)
                    }
                }
                
                // MARK: Если вернулся не особо успешный код, пытаемся достать информацию об ошибке
                return .error(NSError.APIWrapperError.codeIsNotSuccessful(response.statusCode))
            }
    }
    
}
