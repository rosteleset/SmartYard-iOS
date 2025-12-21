//
//  APIWrapper+Extensions.swift
//  SmartYard
//
//  Created by Александр Васильев on 15.03.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import Foundation
import Moya
import RxSwift

extension APIWrapper {
    func getExtensionsList() -> Single<GetExtensionsListResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetExtensionsListRequest(accessToken: accessToken)
        Logger.logDebug("Request data: \(String(describing: request))")

        return provider.rx
            .request(.extList(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getExtension(extId: String) -> Single<GetExtensionResponseData> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetExtensionRequest(accessToken: accessToken, extId: extId)
        Logger.logDebug("Request data: \(String(describing: request))")

        return provider.rx
            .request(.ext(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsDefaultResponse()
    }
    
    func getOptions() -> Single<GetOptionsResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetOptionsRequest(accessToken: accessToken)
        Logger.logDebug("Request data: \(String(describing: request))")

        return provider.rx
            .request(.options(request: request), callbackQueue: .global(qos: .background))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
}
