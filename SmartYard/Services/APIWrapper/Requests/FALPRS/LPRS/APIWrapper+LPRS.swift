//
//  APIWrapper+LPRS.swift
//  SmartYard
//
//  Created by Александр Попов on 09.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxCocoa
import RxSwift

extension APIWrapper {
    
    func getLicensePlates(forFlatId flatId: Int) -> Single<GetLicensePlatesResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }

        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetLicensePlatesRequest(
            accessToken: accessToken,
            flatId: flatId
        )
        Logger.logDebug("Request data: \(String(describing: request))")

        return provider.rx
            .request(.getLicensePlates(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func addLicensePlate(withNumber number : String, forFlatId flatId: Int) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = AddLicensePlateRequest(
            accessToken: accessToken,
            flatId: flatId,
            number: number
        )
        Logger.logDebug("Request data: \(String(describing: request))")
        
        return provider.rx
            .request(.addLicensePlate(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func removeLicensePlate(withNumber number: String, forFlatId flatId: Int) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RemoveLicensePlateRequest(
            accessToken: accessToken,
            flatId: flatId,
            number: number
        )
        Logger.logDebug("Request data: \(String(describing: request))")
        
        return provider.rx
            .request(.removeLicensePlate(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
}
