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
    
    func sendIssue(issueV1: Issue? = nil, issueV2: IssueV2? = nil) -> Single<CreateIssueResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        switch accessService.issuesVersion {
        case "2":
            let request = CreateIssueV2Request(
                accessToken: accessToken,
                issue: issueV2!
            )
            
            return provider.rx
                .request(.createIssueV2(request: request))
                .convertNoConnectionError()
                .mapAsDefaultResponse()
        default:
            let request = CreateIssueRequest(accessToken: accessToken, issue: issueV1!)
            
            return provider.rx
                .request(.createIssue(request: request))
                .convertNoConnectionError()
                .mapAsDefaultResponse()
        }
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
        
        switch accessService.issuesVersion {
        case "2":
            let request = GetListConnectV2Request(accessToken: accessToken, forceRefresh: forceRefresh)
            
            return provider.rx
                .request(.getListConnectV2(request: request))
                .convertNoConnectionError()
                .mapAsEmptyDataInitializableResponse()
                .mapToOptional()
        default:
            let request = GetListConnectRequest(accessToken: accessToken, forceRefresh: forceRefresh)
            
            return provider.rx
                .request(.getListConnect(request: request))
                .convertNoConnectionError()
                .mapAsEmptyDataInitializableResponse()
                .mapToOptional()
        }
    }
    
    func cancelIssue(key: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        switch accessService.issuesVersion {
        case "2":
            let request = ActionIssueV2Request(
                accessToken: accessToken,
                key: key,
                action: .close
            )
            
            return provider.rx
                .request(.actionIssueV2(request: request))
                .convertNoConnectionError()
                .mapAsVoidResponse()
                .mapToOptional()
        default:
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
    }
    
    func changeDeliveryMethod(newMethod: IssueDeliveryType, key: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        switch accessService.issuesVersion {
        case "2":
            let request = ActionIssueV2Request(
                accessToken: accessToken,
                key: key,
                action: .changeQRDeliveryType,
                deliveryType: newMethod
            )
            
            return provider.rx
                .request(.actionIssueV2(request: request))
                .convertNoConnectionError()
                .mapAsVoidResponse()
                .mapToOptional()
        default:
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
    }
    
    func sendCommentAfterDeliveryMethodChanging(newMethod: IssueDeliveryType, key: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        switch accessService.issuesVersion {
        case "2":
            let request = CommentIssueV2Request(
                accessToken: accessToken,
                key: key,
                comment: newMethod.deliveryComment
            )
            
            return provider.rx
                .request(.commentIssueV2(request: request))
                .convertNoConnectionError()
                .mapAsVoidResponse()
                .mapToOptional()
        default:
            let request = CommentIssueRequest(
                accessToken: accessToken,
                key: key,
                comment: newMethod.deliveryComment
            )
            
            return provider.rx
                .request(.commentIssue(request: request))
                .convertNoConnectionError()
                .mapAsVoidResponse()
                .mapToOptional()
        }
    }
    
}
