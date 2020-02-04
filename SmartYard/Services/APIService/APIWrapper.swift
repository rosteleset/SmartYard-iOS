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
    let accessService: AccessService
    
    let login = "f70392"
    let password = "d342a76ec"
    
    init(apiService: APIService, accessService: AccessService) {
        self.apiService = apiService
        self.accessService = accessService
    }
    
    func requestCode(userPhone: String) -> Completable {
        let request = RequestCodeRequest(userPhone: userPhone)
        
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performRequestCodeRequest(request) { result in
                switch result {
                case .success: completable(.completed)
                case let .failure(error): completable(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func confirmCode(userPhone: String, smsCode: String) -> Single<ConfirmCodeResponseData> {
        guard accessService.accessToken == nil && accessService.clientId == nil else {
            return .error(NSError.APIWrapperError.alreadyLoggedInError)
        }
        
        let request = ConfirmCodeRequest(userPhone: userPhone, smsCode: smsCode)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performConfirmCodeRequest(request) { [weak self] result in
                switch result {
                case let .success(data):
                    self?.accessService.accessToken = data.accessToken
                    
                    single(.success(data))
                    
                case let .failure(error):
                    single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func login(login: String, password: String) -> Single<LoginResponseData> {
        guard accessService.accessToken == nil && accessService.clientId == nil else {
            return .error(NSError.APIWrapperError.alreadyLoggedInError)
        }
        
        let request = LoginRequest(login: login, password: password)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performLoginRequest(request) { [weak self] result in
                switch result {
                case let .success(data):
                    self?.accessService.accessToken = data.accessToken
                    self?.accessService.clientId = data.clientId
                    
                    single(.success(data))
                    
                case let .failure(error):
                    single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func getVerifyedAddresses() -> Single<GetVerifyedAddressesResponseData> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = GetVerifyedAddressesRequest(accessToken: accessToken)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performGetVerifyedAddressesRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func registerToken(pushToken: String, type: TokenType) -> Completable {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        guard let clientId = accessService.clientId else {
            return .error(NSError.APIWrapperError.clientIdMissingError)
        }
        
        let request = RegisterTokenRequest(
            accessToken: accessToken,
            pushToken: pushToken,
            clientId: clientId,
            type: type
        )
        
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performRegisterTokenRequest(request) { result in
                switch result {
                case .success: completable(.completed)
                case let .failure(error): completable(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func updateTokenState(pushToken: String, newState: TokenState) -> Completable {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        guard let clientId = accessService.clientId else {
            return .error(NSError.APIWrapperError.clientIdMissingError)
        }
        
        let request = IntercomTokenRequest(
            accessToken: accessToken,
            pushToken: pushToken,
            clientId: clientId,
            state: newState
        )
        
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
    
    func checkTokenState(pushToken: String) -> Single<IntercomTokenResponseData> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        guard let clientId = accessService.clientId else {
            return .error(NSError.APIWrapperError.clientIdMissingError)
        }
        
        let request = IntercomTokenRequest(
            accessToken: accessToken,
            pushToken: pushToken,
            clientId: clientId,
            state: nil
        )
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performCheckTokenStateRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
}
