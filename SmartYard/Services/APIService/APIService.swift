//
//  APIService.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Moya
import Alamofire

class APIService {
    
    private let provider: MoyaProvider<APITarget> = {
        let manager = SessionManager()
        manager.retrier = BaseRequestRetrier()
        return MoyaProvider<APITarget>(manager: manager)
    }()
    
    var isReachable: Bool {
        return NetworkReachabilityManager()?.isReachable ?? false
    }
    
    /// Запрос получения СМС-кода
    func performRequestCodeRequest(
        _ request: RequestCodeRequest,
        completion: ((Swift.Result<Void, Error>) -> Void)?
    ) {
        provider.request(
            .requestCode(request: request),
            completion: createEmptyInnerCompletionBlock(from: completion)
        )
    }
    
    /// Запрос подтверждения СМС-кода
    func performConfirmCodeRequest(
        _ request: ConfirmCodeRequest,
        completion: ((Swift.Result<ConfirmCodeResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .confirmCode(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос логина
    func performLoginRequest(
        _ request: LoginRequest,
        completion: ((Swift.Result<LoginResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .login(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос подтвержденных адресов
    func performGetVerifyedAddressesRequest(
        _ request: GetVerifyedAddressesRequest,
        completion: ((Swift.Result<GetVerifyedAddressesResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .getVerifyedAddresses(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос отправки токена на сервер
    func performRegisterTokenRequest(
        _ request: RegisterTokenRequest,
        completion: ((Swift.Result<Void, Error>) -> Void)?
    ) {
        provider.request(
            .registerToken(request: request),
            completion: createEmptyInnerCompletionBlock(from: completion)
        )
    }
    
    /// Запрос модификации статуса токена на сервере
    func performUpdateTokenStateRequest(
        _ request: IntercomTokenRequest,
        completion: ((Swift.Result<Void, Error>) -> Void)?
    ) {
        provider.request(
            .intercomToken(request: request),
            completion: createEmptyInnerCompletionBlock(from: completion)
        )
    }
    
    /// Запрос получения статуса токена с сервера
    func performCheckTokenStateRequest(
        _ request: IntercomTokenRequest,
        completion: ((Swift.Result<IntercomTokenResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .intercomToken(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос изменения имени пользователя
    func performSendNameRequest(
        _ request: SendNameRequest,
        completion: ((Swift.Result<Void, Error>) -> Void)?
    ) {
        provider.request(
            .sendName(request: request),
            completion: createEmptyInnerCompletionBlock(from: completion)
        )
    }
    
}

extension APIService {
    
    // MARK: Mapping queries with required Data block
    
    private func createInnerCompletionBlockWithData<T: Decodable>(
        from outerBlock: ((Swift.Result<T, Error>) -> Void)?
    ) -> Completion {
        return { [weak self] result in
            guard let self = self else {
                return
            }
            
            let convertedResult: Swift.Result<T, Error> = {
                switch result {
                case .success(let response): return self.mapResponseWithData(response)
                case .failure(let error): return .failure(error)
                }
            }()
            
            outerBlock?(convertedResult)
        }
    }
    
    private func mapResponseWithData<T: Decodable>(_ response: Response) -> Swift.Result<T, Error> {
        do {
            guard response.statusCode == 200 else {
                let error = NSError(domain: "APIServiceError", code: response.statusCode, userInfo: nil)
                return .failure(error)
            }
            
            let mappedResponse = try response.map(BaseAPIResponse<T>.self)
            
            return .success(mappedResponse.data)
        } catch {
            return .failure(NSError.APIServiceError.mappingError)
        }
    }
    
}

extension APIService {
    
    // MARK: Mapping queries with empty Data block
    
    private func createEmptyInnerCompletionBlock(
        from outerBlock: ((Swift.Result<Void, Error>) -> Void)?
    ) -> Completion {
        return { [weak self] result in
            guard let self = self else {
                return
            }
            
            let convertedResult: Swift.Result<Void, Error> = {
                switch result {
                case .success(let response): return self.mapEmptyResponse(response)
                case .failure(let error): return .failure(error)
                }
            }()
            
            outerBlock?(convertedResult)
        }
    }
    
    private func mapEmptyResponse(_ response: Response) -> Swift.Result<Void, Error> {
        guard response.statusCode == 200 || response.statusCode == 204 else {
            let error = NSError(domain: "APIServiceError", code: response.statusCode, userInfo: nil)
            return .failure(error)
        }
        
        return .success(())
    }
    
}
