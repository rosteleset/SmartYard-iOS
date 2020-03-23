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
        userInfo: MainUserInfo,
        lat: String? = nil,
        lng: String? = nil
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
        
        let latitude = (lat ?? "").replacingOccurrences(of: ".", with: ",")
        let longitude = (lng ?? "").replacingOccurrences(of: ".", with: ",")
        
        let customField = APIIssueCustomField(
            code: issue.clientCode,
            phoneNumber: userInfo.phoneNumber,
            source: "Приложение",
            lat: latitude,
            lng: longitude
        )
        
        let request = CreateIssueRequest(
            accessToken: accessToken,
            issue: apiIssue,
            customFields: customField,
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
            .map(BaseAPIResponse<GetListConnectResponseData>.self)
            .flatMap { response in
                if let data = response.data {
                    return .just(data)
                } else if response.code == 204 {
                    return .just([])
                } else {
                    return .error(NSError.APIWrapperError.noDataError)
                }
            }
    }
    
}
