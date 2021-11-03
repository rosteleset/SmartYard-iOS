//
//  APIWrapper+Issues.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension APIWrapper {
    
    func sendIssue(issue: Issue) -> Single<CreateIssueResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = CreateIssueRequest(accessToken: accessToken, issue: issue)
        
        return provider.rx
            .request(.createIssue(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func getListConnect(forceRefresh: Bool = false) -> Single<GetListConnectResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let forceRefresh = forceUpdateIssues || forceRefresh
        forceUpdateIssues = false
        
        let request = GetListConnectRequest(accessToken: accessToken, forceRefresh: forceRefresh)
        
        return provider.rx
            .request(.getListConnect(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func cancelIssue(key: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
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
            .request(.actionIssue(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func changeDeliveryMethod(newMethod: IssueDeliveryType, key: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
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
            .request(.actionIssue(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func sendCommentAfterDeliveryMethodChanging(newMethod: IssueDeliveryType, key: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = CommentIssueRequest(accessToken: accessToken, key: key, comment: newMethod.deliveryComment)
        
        return provider.rx
            .request(.commentIssue(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
}
