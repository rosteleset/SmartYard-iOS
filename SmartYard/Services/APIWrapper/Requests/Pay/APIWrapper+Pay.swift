//
//  APIWrapper+Pay.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 13.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya

extension APIWrapper {
    
    func payBalanceDetail(id: String, to: String?, from: String?) -> Single<DetailResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = DetailRequest(accessToken: accessToken, id: id, to: to, from: from)
        
        return provider.rx
            .request(.payBalanceDetail(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func checkPay(merchant: Merchant, orderId: String) -> Single<CheckPayResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = CheckPayRequest(accessToken: accessToken, merchant: merchant, orderId: orderId)
        
        return provider.rx
            .request(.payCheck(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func autoPay(merchant: Merchant, contractName: String, summa: Double, description: String, bindingId: String, check: CheckSendType, email: String? = nil) -> Single<CheckPayResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = AutoPayRequest(
            accessToken: accessToken,
            merchant: merchant,
            contractName: contractName,
            summa: summa,
            description: description,
            bindingId: bindingId,
            notifyMethod: check,
            email: email
        )
        
        return provider.rx
            .request(.payAuto(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func newPay(merchant: Merchant, contractName: String, summa: Double, description: String, returnUrl: String) -> Single<NewPayResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = NewPayRequest(accessToken: accessToken, merchant: merchant, contractName: contractName, summa: summa, description: description, returnUrl: returnUrl)

        return provider.rx
            .request(.payNew(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
//            .mapToOptional()
    }
    
    func getCards(contractName: String) -> Single<GetCardsResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetCardsRequest(accessToken: accessToken, contractName: contractName)
        
        return provider.rx
            .request(.payGetCards(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
//            .mapToOptional()
    }
    
    func createNewSBPPay(merchant: Merchant, contractName: String, summa: Double, description: String, check: CheckSendType, email: String? = nil) -> Single<CreateSBPOrderResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }

        let request = CreateSBPOrderRequest(
            accessToken: accessToken,
            merchant: merchant,
            contractName: contractName,
            summa: summa,
            description: description,
            notifyMethod: check,
            email: email
        )

        return provider.rx
            .request(.newSBPPay(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
//            .mapToOptional()
    }
    
    func updateSBPPay(merchant: Merchant, id: String, status: Int, orderId: String? = nil, processed: Date? = nil, isTest: Bool = false) -> Single<UpdateSBPOrderResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = UpdateSBPOrderRequest(
            accessToken: accessToken,
            merchant: merchant,
            id: id,
            status: status,
            orderId: orderId,
            processed: processed,
            isTest: isTest
        )
        
        return provider.rx
            .request(.updateSBPPay(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func yooKassaNewPay(
        merchant: Merchant,
        paymentToken: String,
        contractName: String,
        summa: Double,
        description: String,
        check: CheckSendType,
        isAutopay: Bool = true,
        isCardSave: Bool = true,
        email: String? = nil
    ) -> Single<YooKassaNewPayResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }

        let request = YooKassaNewPayRequest(
            accessToken: accessToken,
            merchant: merchant,
            paymentToken: paymentToken,
            contractName: contractName,
            summa: summa,
            description: description,
            isCardSave: isCardSave,
            isAutopay: isAutopay,
            notifyMethod: check,
            email: email
        )

        return provider.rx
            .request(.yooKassaNewPay(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func sendBalanceDetails(id: String, contract: String, to: String, from: String, mail: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = SendDetailRequest(accessToken: accessToken, id: id, contract: contract, to: to, from: from, mail: mail)
        
        return provider.rx
            .request(.paySendDetail(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func removeCard(merchant: Merchant, bindingId: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }

        let request = RemoveCardRequest(accessToken: accessToken, merchant: merchant, bindingId: bindingId)
        
        return provider.rx
            .request(.payRemoveCard(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func addAutopay(merchant: Merchant, bindingId: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }

        let request = AddAutopayRequest(accessToken: accessToken, merchant: merchant, bindingId: bindingId)
        
        return provider.rx
            .request(.addAutopay(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func removeAutopay(merchant: Merchant, bindingId: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }

        let request = RemoveAutopayRequest(accessToken: accessToken, merchant: merchant, bindingId: bindingId)
        
        return provider.rx
            .request(.removeAutopay(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
}
