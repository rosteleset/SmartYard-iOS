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
    let accessToken = "79902143-88e4-46fd-a2ed-2bd0b132c433:6ebba629d6adbace8fbb974fd0aa4795"
    let clientId = "75549"
    
    init(apiService: APIService) {
        self.apiService = apiService
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
        let request = ConfirmCodeRequest(userPhone: userPhone, smsCode: smsCode)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performConfirmCodeRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func login(login: String, password: String) -> Single<LoginResponseData> {
        let request = LoginRequest(login: login, password: password)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performLoginRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func getVerifyedAddresses() -> Single<GetVerifyedAddressesResponseData> {
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
