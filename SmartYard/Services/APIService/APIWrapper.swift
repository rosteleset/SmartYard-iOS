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
    
    func requestCode(userPhone: String) -> Single<Void?> {
        let request = RequestCodeRequest(userPhone: userPhone)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performRequestCodeRequest(request) { result in
                switch result {
                case .success: single(.success(()))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func confirmCode(userPhone: String, smsCode: String) -> Single<ConfirmCodeResponseData?> {
        guard accessService.accessToken == nil else {
            return .error(NSError.APIWrapperError.alreadyLoggedInError)
        }
        
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
    
    func login(login: String, password: String) -> Single<LoginResponseData?> {
        guard accessService.accessToken == nil else {
            return .error(NSError.APIWrapperError.alreadyLoggedInError)
        }
        
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
    
    func getVerifyedAddresses() -> Single<GetVerifyedAddressesResponseData?> {
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
    
    func registerToken(pushToken: String, clientId: String?, type: TokenType) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RegisterTokenRequest(
            accessToken: accessToken,
            pushToken: pushToken,
            clientId: clientId,
            type: type
        )
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performRegisterTokenRequest(request) { result in
                switch result {
                case .success: single(.success(()))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func updateTokenState(pushToken: String, clientId: String, newState: TokenState) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = IntercomTokenRequest(
            accessToken: accessToken,
            pushToken: pushToken,
            clientId: clientId,
            state: newState
        )
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performUpdateTokenStateRequest(request) { result in
                switch result {
                case .success: single(.success(()))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func checkTokenState(pushToken: String, clientId: String) -> Single<IntercomTokenResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
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
    
    func sendName(name: String, patronymic: String?) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = SendNameRequest(accessToken: accessToken, name: name, patronymic: patronymic)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performSendNameRequest(request) { result in
                switch result {
                case .success: single(.success(()))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func openDoor(domophoneId: String, doorId: Int?) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = OpenDoorRequest(accessToken: accessToken, domophoneId: domophoneId, doorId: doorId)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performOpenDoorRequest(request) { result in
                switch result {
                case .success: single(.success(()))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func grantHourGuestAccess(flatId: String) -> Single<HourGuestAccessResponseData?> {
        let autoOpenEndDate = Date().dateHourAfter.apiString
        
        let settings = APIIntercomSettings(
            enableDoorCode: "t",
            cms: nil,
            voip: nil,
            autoOpen: autoOpenEndDate,
            whiteRabbit: nil
        )
        
        let request = HourGuestAccessRequest(flatId: flatId, settings: settings)
        
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.GenericError.selfIsDeadError))
                return Disposables.create()
            }
            
            self.apiService.performGrantHourGuestAccessRequest(request) { result in
                switch result {
                case let .success(data): single(.success(data))
                case let .failure(error): single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
}
