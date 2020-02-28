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
        selectedService: SettingsServiceType? = nil,
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
        
        
        let customField = APIIssueCustomField(
            code: issue.clientCode,
            phoneNumber: userInfo.phoneNumber,
            source: "Приложение",
            lat: "41,40407",//lat ?? "-",
            lng: "52,771197"//lng ?? "-"
        )
        
        let actions = ["Начать работу", "Позвонить"]
        
        let request = CreateIssueRequest(
            accessToken: accessToken,
            issue: apiIssue,
            customFields: customField,
            actions: actions
        )
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performCreateIssueRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func getListConnect() -> Single<GetListConnectResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetListConnectRequest(accessToken: accessToken)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performGetListConnectRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
}
