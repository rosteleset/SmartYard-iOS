//
//  APIWrapper+FRS.swift
//  SmartYard
//
//  Created by Александр Васильев on 12.05.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxCocoa
import RxSwift

import Foundation

extension APIWrapper {
    
    func getPersonFaces(flatId: Int, forceRefresh: Bool = false) -> Single<GetPersonFacesResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let forceRefresh = forceUpdateFaces || forceRefresh
        forceUpdateFaces = false
        
        let request = GetPersonFacesRequest(
            accessToken: accessToken,
            forceRefresh: forceRefresh,
            flatId: flatId
        )
        Logger.logDebug("Request data: \(String(describing: request))")

        return provider.rx
            .request(.getPersonFaces(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func disLikePersonFace(event uuid: String) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = DisLikePersonFaceRequest(
            accessToken: accessToken,
            event: uuid
        )
        Logger.logDebug("Request data: \(String(describing: request))")

        return provider.rx
            .request(.disLikePersonFace(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func disLikePersonFace(flatId: Int, faceId: Int) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RemovePersonFaceRequest(
            accessToken: accessToken,
            flatId: flatId,
            faceId: faceId
        )
        Logger.logDebug("Request data: \(String(describing: request))")

        return provider.rx
            .request(.removePersonFace(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func likePersonFace(event uuid: String) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = LikePersonFaceRequest(
            accessToken: accessToken,
            event: uuid
        )
        Logger.logDebug("Request data: \(String(describing: request))")

        return provider.rx
            .request(.likePersonFace(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
}
