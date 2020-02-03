//
//  APIWrapper.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Moya
import Alamofire
import RxSwift
import RxCocoa

class APIWrapper {
    
    let apiService: APIService
    
    let login = "f70392"
    let password = "d342a76ec"
    let phone = "89278339622"
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func sendToken(token: String, tokenType: TokenType) -> Completable {
        let request = SendTokenRequest(login: login, password: password, token: token, tokenType: tokenType)
        
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performSendTokenRequest(request) { result in
                switch result {
                case .success: completable(.completed)
                case let .failure(error): completable(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func updateTokenState(token: String, isEnabled: Bool) -> Completable {
        let request = UpdateTokenStateRequest(login: login, password: password, token: token, isEnabled: isEnabled)
        
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performUpdateTokenStateRequest(request) { result in
                switch result {
                case .success: completable(.completed)
                case let .failure(error): completable(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func checkTokenState(token: String) -> Completable {
        let request = CheckTokenStateRequest(login: login, password: password, token: token)
        
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performCheckTokenStateRequest(request) { result in
                switch result {
                case .success: completable(.completed)
                case let .failure(error): completable(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
}
