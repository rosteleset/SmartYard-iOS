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
    
    /// Запрос отправки токена на сервер
    func performSendTokenRequest(
        _ request: SendTokenRequest,
        completion: ((Swift.Result<Void, Error>) -> Void)?
    ) {
        provider.request(
            .sendToken(request: request),
            completion: createDefaultInnerCompletion(from: completion)
        )
    }
    
    /// Запрос включения / выключения токена
    func performUpdateTokenStateRequest(
        _ request: UpdateTokenStateRequest,
        completion: ((Swift.Result<Void, Error>) -> Void)?
    ) {
        provider.request(
            .updateTokenState(request: request),
            completion: createDefaultInnerCompletion(from: completion)
        )
    }
    
    /// Запрос проверки статуса токена на сервере
    func performCheckTokenStateRequest(
        _ request: CheckTokenStateRequest,
        completion: ((Swift.Result<Void, Error>) -> Void)?
    ) {
        provider.request(
            .checkTokenState(request: request),
            completion: createDefaultInnerCompletion(from: completion)
        )
    }
    
    // MARK: Маппинг
    
    private func createDefaultInnerCompletion(
        from completion: ((Swift.Result<Void, Error>) -> Void)?
    ) -> Completion {
        let innerCompletion: Completion = { result in
            switch result {
            case let .success(response):
                do {
                    let mappedResponse = try response.map(BaseAPIResponse.self)
                    
                    guard mappedResponse.message == "хорошо" else {
                        completion?(.failure(NSError.APIServiceError.unknownError))
                        return
                    }
                    
                    completion?(.success(()))
                } catch {
                    completion?(.failure(NSError.APIServiceError.mappingError))
                }
            case let .failure(error):
                completion?(.failure(error))
            }
        }
        
        return innerCompletion
    }
    
}
