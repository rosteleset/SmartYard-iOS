//
//  APIWrapper+Issues.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension APIWrapper {
    
    func sendIssue(issue: Issue) -> Single<CreateIssueResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = CreateIssueRequest(accessToken: accessToken, issue: issue)
        
        return provider.rx
            .request(.createIssue(request: request))
            .filterSuccessfulCodes()
            .map(BaseAPIResponse<CreateIssueResponseData>.self)
            .flatMap { response in
                guard let data = response.data else {
                    return .error(NSError.APIWrapperError.noDataError)
                }
                
                return .just(data)
            }
    }
    
    func getListConnect() -> Single<GetListConnectResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetListConnectRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.getListConnect(request: request))
            .filterSuccessfulCodes()
            .mapAsEmptyDataInitializable()
            .mapToOptional()
    }
    
    func cancelIssue(key: String) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = ActionIssueRequest(
            accessToken: accessToken,
            key: key,
            action: "Jelly.Закрыть авто",
            customFields: nil
        )
        
        return provider.rx
            .request(.cancelIssue(request: request))
            .filterSuccessfulCodes()
            .map { _ in }
    }
    
    func changeDeliveryMethod(newMethod: IssueDeliveryType, key: String) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
    
        let request = ActionIssueRequest(
            accessToken: accessToken,
            key: key,
            action: "Jelly.Способ доставки",
            customFields: newMethod.deliveryCustomFields
        )
        
        return provider.rx
            .request(.cancelIssue(request: request))
            .filterSuccessfulCodes()
            .map { _ in }
    }
    
    func sendCommentAfterDeliveryMethodChanging(newMethod: IssueDeliveryType, key: String) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = CommentIssueRequest(accessToken: accessToken, key: key, comment: newMethod.deliveryComment)
        
        return provider.rx
            .request(.commentIssue(request: request))
            .filterSuccessfulCodes()
            .map { _ in }
    }
    
}
