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
    
    func createIssue(
        issue: IssueType,
        customFields: [String: String]
    ) -> Single<CreateIssueResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let apiIssue = APIIssue(
            project: "REM",
            summary: issue.summary,
            description: issue.description,
            type: "32"
        )
//
//        let latitude = (lat ?? "").replacingOccurrences(of: ".", with: ",")
//        let longitude = (lng ?? "").replacingOccurrences(of: ".", with: ",")
        
        let request = CreateIssueRequest(
            accessToken: accessToken,
            issue: apiIssue,
            customFields: customFields,
            actions: issue.actions
        )
        
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
