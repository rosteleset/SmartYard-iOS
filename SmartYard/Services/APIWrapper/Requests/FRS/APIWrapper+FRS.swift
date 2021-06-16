//
//  APIWrapper+FRS.swift
//  SmartYard
//
//  Created by Александр Васильев on 12.05.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension APIWrapper {
    
    func getPersonFaces(flatId: Int, forceRefresh: Bool = false) -> Single<GetPersonFacesResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let forceRefresh = forceUpdateFaces || forceRefresh
        forceUpdateFaces = false
        
        let request = GetPersonFacesRequest(accessToken: accessToken, forceRefresh: forceRefresh, flatId: flatId)
        print("request data: \(request)")
        
        return provider.rx
            .request(.getPersonFaces(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func disLikePersonFace(event uuid: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = DisLikePersonFaceRequest(
            accessToken: accessToken,
            event: uuid
        )
        print("request data: \(request)")
        
        return provider.rx
            .request(.disLikePersonFace(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func disLikePersonFace(flatId: Int, faceId: Int) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RemovePersonFaceRequest(
            accessToken: accessToken,
            flatId: flatId,
            faceId: faceId
        )
        print("request data: \(request)")
        
        return provider.rx
            .request(.removePersonFace(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func likePersonFace(event uuid: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = LikePersonFaceRequest(
            accessToken: accessToken,
            event: uuid
        )
        print("request data: \(request)")
        
        return provider.rx
            .request(.likePersonFace(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
}
