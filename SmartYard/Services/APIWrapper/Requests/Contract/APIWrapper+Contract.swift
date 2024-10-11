//
//  APIWrapper+Contract.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 17.09.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya

extension APIWrapper {
    func activateLimit(contractId: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }

        let request = ActivateLimitRequest(accessToken: accessToken, contractId: contractId)
        
        return provider.rx
            .request(.activateLimit(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
}
