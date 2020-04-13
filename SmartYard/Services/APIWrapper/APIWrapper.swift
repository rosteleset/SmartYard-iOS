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
    
    func mapAsVoidResponse() -> Single<Void> {
        return flatMap { response in
            // MARK: Если вернулся успешный код, то просто возвращаем Void

            if 200...299 ~= response.statusCode {
                return .just(())
            }

            // MARK: Если вернулся не особо успешный код, пытаемся достать информацию об ошибке
            
            return .error(response.extractBaseAPIResponseError())
        }
    }
    
    func mapAsDefaultResponse<T: Decodable>() -> Single<T> {
        return flatMap { response in
            // MARK: Если вернулся успешный код - пытаемся замапить реквест
            
            if 200...299 ~= response.statusCode {
                do {
                    let mappedResponse = try response.map(BaseAPIResponse<T>.self)
                    
                    guard let data = mappedResponse.data else {
                        return .error(NSError.APIWrapperError.noDataError)
                    }
                    
                    return .just(data)
                } catch {
                    return .error(NSError.APIWrapperError.baseResponseMappingError)
                }
            }
            
            // MARK: Если вернулся не особо успешный код, пытаемся достать информацию об ошибке
            
            return .error(response.extractBaseAPIResponseError())
        }
    }
    
    func mapAsEmptyDataInitializableResponse<T: Decodable & EmptyDataInitializable>() -> Single<T> {
        return flatMap { response in
            // MARK: Если вернулся код 204 (пустой контент), то просто возвращаем пустой контент
            
            if response.statusCode == 204 {
                return .just(T())
            }
            
            // MARK: Если вернулся успешный код - пытаемся замапить реквест
            
            if 200...299 ~= response.statusCode {
                do {
                    let mappedResponse = try response.map(BaseAPIResponse<T>.self)
                    
                    guard let data = mappedResponse.data else {
                        return .error(NSError.APIWrapperError.noDataError)
                    }
                    
                    return .just(data)
                } catch {
                    return .error(NSError.APIWrapperError.baseResponseMappingError)
                }
            }
            
            // MARK: Если вернулся не особо успешный код, пытаемся достать информацию об ошибке
            
            return .error(response.extractBaseAPIResponseError())
        }
    }
    
}

extension Response {
    
    func extractBaseAPIResponseError() -> Error {
        do {
            let mappedResponse = try map(BaseAPIResponse<String>.self)
            
            return NSError.APIWrapperError.codeIsNotSuccessfulExtended(
                code: mappedResponse.code,
                message: mappedResponse.message
            )
        } catch {
            return NSError.APIWrapperError.codeIsNotSuccessful(statusCode)
        }
    }
    
}

extension PrimitiveSequence where Trait == SingleTrait {
    
    func mapToOptional() -> Single<Element?> {
        return map { $0 }
    }
    
}
