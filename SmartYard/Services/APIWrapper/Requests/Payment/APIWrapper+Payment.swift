//
//  APIWrapper+Payment.swift
//  SmartYard
//
//  Created by Mad Brains on 14.05.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
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
    
}
