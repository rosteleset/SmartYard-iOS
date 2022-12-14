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
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetExtensionsListRequest(accessToken: accessToken)
        print("request data: \(request)")
        
        return provider.rx
            .request(.extList(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getExtension(extId: String) -> Single<GetExtensionResponseData> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetExtensionRequest(accessToken: accessToken, extId: extId)
        print("request data: \(request)")
        
        return provider.rx
            .request(.ext(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func getOptions() -> Single<GetOptionsResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetOptionsRequest(accessToken: accessToken)
        print("request data: \(request)")
        
        return provider.rx
            .request(.options(request: request), callbackQueue: .global(qos: .background))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
}
