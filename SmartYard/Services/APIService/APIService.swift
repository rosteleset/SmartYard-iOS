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
        completion: ((Swift.Result<Data?, Error>) -> Void)?
    ) {
        provider.request(
            .requestCode(request: request),
            completion: createInnerCompletionBlock(from: completion)
        )
    }
    
    /// Запрос подтверждения СМС-кода
    func performConfirmCodeRequest(
        _ request: ConfirmCodeRequest,
        completion: ((Swift.Result<ConfirmCodeResponseData?, Error>) -> Void)?
    ) {
        provider.request(
            .confirmCode(request: request),
            completion: createInnerCompletionBlock(from: completion)
        )
    }
    
    /// Запрос логина
    func performLoginRequest(
        _ request: LoginRequest,
        completion: ((Swift.Result<LoginResponseData?, Error>) -> Void)?
    ) {
        provider.request(
            .login(request: request),
            completion: createInnerCompletionBlock(from: completion)
        )
    }
    
    /// Запрос подтвержденных адресов
    func performGetVerifyedAddressesRequest(
        _ request: GetVerifyedAddressesRequest,
        completion: ((Swift.Result<GetVerifyedAddressesResponseData?, Error>) -> Void)?
    ) {
        provider.request(
            .getVerifyedAddresses(request: request),
            completion: createInnerCompletionBlock(from: completion)
        )
    }
    
    /// Запрос отправки токена на сервер
    func performRegisterTokenRequest(
        _ request: RegisterTokenRequest,
        completion: ((Swift.Result<Data?, Error>) -> Void)?
    ) {
        provider.request(
            .registerToken(request: request),
            completion: createInnerCompletionBlock(from: completion)
        )
    }
    
    /// Запрос статуса токена на сервере
    func performIntercomTokenRequest(
        _ request: IntercomTokenRequest,
        completion: ((Swift.Result<IntercomTokenResponseData?, Error>) -> Void)?
    ) {
        provider.request(
            .intercomToken(request: request),
            completion: createInnerCompletionBlock(from: completion)
        )
    }
    
    // MARK: Mapping
    
    private func createInnerCompletionBlock<T: Decodable>(
        from outerBlock: ((Swift.Result<T?, Error>) -> Void)?
    ) -> Completion {
        return { [weak self] result in
            guard let self = self else {
                return
            }
            
            let convertedResult: Swift.Result<Response, MoyaError> = {
                switch result {
                case .success(let response): return .success(response)
                case .failure(let error): return .failure(error)
                }
            }()
            
            outerBlock?(self.mapRequestResult(convertedResult))
        }
    }
    
    private func mapRequestResult<T: Decodable>(
        _ result: Swift.Result<Response, MoyaError>
    ) -> Swift.Result<T?, Error> {
        switch result {
        case .success(let response): return mapResponse(response)
        case .failure(let error): return .failure(error)
        }
    }
    
    private func mapResponse<T: Decodable>(_ response: Response) -> Swift.Result<T?, Error> {
        do {
            let mappedResponse = try response.map(BaseAPIResponse<T>.self)
            
            guard mappedResponse.code == 200 else {
                let errorUserInfo = [NSLocalizedDescriptionKey: mappedResponse.name + mappedResponse.message]
                let error = NSError(domain: "APIServiceError", code: mappedResponse.code, userInfo: errorUserInfo)
                return .failure(error)
            }
            
            return .success(mappedResponse.data)
        } catch {
            let errorUserInfo = [NSLocalizedDescriptionKey: "Ошибка маппинга данных"]
            let error = NSError(
                domain: "RestAPIServiceError",
                code: 2002,
                userInfo: errorUserInfo
            )
            return .failure(error)
        }
    }
    
}
