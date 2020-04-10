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
    
    let accessService: AccessService
    
    let provider: MoyaProvider<APITarget> = {
        let session = Session(interceptor: BaseRequestRetrier())
        return MoyaProvider<APITarget>(session: session)
    }()
    
    var isReachable: Bool {
        return NetworkReachabilityManager()?.isReachable ?? false
    }
    
    init(accessService: AccessService) {
        self.accessService = accessService
    }
    
}

extension PrimitiveSequence where Trait == SingleTrait, Element == Response {
    
    func filterSuccessfulCodes() -> Single<Response> {
        return flatMap { response in
            guard 200...299 ~= response.statusCode else {
                return .error(NSError.APIWrapperError.codeIsNotSuccessful(response.statusCode))
            }
            
            return .just(response)
        }
    }
    
    func mapAsDefaultResponse<T: Decodable>() -> Single<T> {
        return flatMap { response in
            // MARK: Если успех (code == 200), то пытаемся просто замапить реквест
            
            guard response.statusCode != 200 else {
                do {
                    let mappedResponse = try response.map(BaseAPIResponse<T>.self)
                    
                    if let data = mappedResponse.data {
                        return .just(data)
                    } else {
                        return .error(NSError.APIWrapperError.noDataError)
                    }
                } catch {
                    return .error(NSError.APIWrapperError.baseResponseMappingError)
                }
            }
            
            // MARK: Если код отличается от 200, пытаемся достать информацию об ошибке
            
            do {
                let mappedResponse = try response.map(BaseAPIResponse<T>.self)
                
                return .error(
                    NSError.APIWrapperError.codeIsNotSuccessfulExtended(
                        code: mappedResponse.code,
                        name: mappedResponse.name,
                        message: mappedResponse.message
                    )
                )
            } catch {
                return .error(NSError.APIWrapperError.codeIsNotSuccessful(response.statusCode))
            }
        }
    }
    
    func mapAsEmptyDataInitializableResponse<T: Decodable & EmptyDataInitializable>() -> Single<T> {
        return flatMap { response in
            // MARK: Если вернулся код 204 (пустой контент), то просто возвращаем пустой контент
            
            if response.statusCode == 204 {
                return .just(T())
            }
            
            // MARK: Иначе - мапим ровно так же, как и обычный респонз
            
            return self.mapAsDefaultResponse()
        }
    }
    
}

extension PrimitiveSequence where Trait == SingleTrait {
    
    func mapToOptional() -> Single<Element?> {
        return map { $0 }
    }
    
}
