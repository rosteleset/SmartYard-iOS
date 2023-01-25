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
    
    func payRegisterProcess(orderNumber: String, amount: String) -> Single<PayRegisterResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        let request = PayRegisterRequest(
            orderNumber: orderNumber,
            amount: amount
        )

        print(request)
        
        return provider.rx
            .request(.payRegister(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
}
