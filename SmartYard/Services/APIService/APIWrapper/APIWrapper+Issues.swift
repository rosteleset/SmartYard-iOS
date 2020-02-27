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
        userName: String,
        phoneNumber: String,
        selectedService: SettingsServiceType,
        lat: String,
        lng: String
    ) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let issueDescription = "Имя: \(userName)\nЗаявка на отключение/подключение услуги \(selectedService)"
        
        let apiIssue = APIIssue(
            project: "REM",
            summary: "Авто: Заявка с сайта",
            description: issueDescription,
            type: "32"
        )
        
        let customField = APIIssueCustomField(
            code: "-1",
            phoneNumber: phoneNumber,
            source: "Приложение",
            lat: lat,
            lng: lng
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
                case .success: single(.success(()))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
}
