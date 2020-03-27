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
    
    func createIssue(issue: Issue) -> Single<CreateIssueResponseData?> {
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
    
}
