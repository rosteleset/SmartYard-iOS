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
    
    func createIssue() -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let apiIssue = APIIssue(name: "test", value: "test")
        
        let request = CreateIssueRequest(
            accessToken: accessToken,
            issue: [apiIssue],
            customFields: nil,
            actions: nil
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
