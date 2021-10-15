//
//  APIWrapper.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Moya
import Alamofire
import RxSwift
import RxCocoa

class APIWrapper {
    
    let reachability: NetworkReachabilityManager
    let accessService: AccessService
    
    let isReachableObservable: BehaviorSubject<Bool>
    
    let provider: MoyaProvider<APITarget> = {
        let session = Session(interceptor: BaseRequestRetrier())
        return MoyaProvider<APITarget>(session: session)
    }()
    
    var forceUpdateFaces: Bool = false
    var forceUpdateSettings: Bool = false
    var forceUpdateAddress: Bool = false
    var forceUpdatePayments: Bool = false
    var forceUpdateIssues: Bool = false
    
    
    var isReachable: Bool {
        return reachability.isReachable
    }
    
    init(accessService: AccessService) {
        self.accessService = accessService
        
        reachability = NetworkReachabilityManager()!
        
        isReachableObservable = BehaviorSubject<Bool>(value: reachability.isReachable)
        
        reachability.startListening { [weak self] status in
            if case .reachable = status {
                self?.isReachableObservable.onNext(true)
            } else {
                self?.isReachableObservable.onNext(false)
            }
        }
    }
    
}

extension PrimitiveSequence where Trait == SingleTrait, Element == Response {
    
    func mapAsVoidResponse() -> Single<Void> {
        return flatMap { response in
            // MARK: Если вернулся успешный код, то просто возвращаем Void

            if 200...299 ~= response.statusCode {
                print("response data: <empty>")
                return .just(())
            }

            // MARK: Если вернулся не особо успешный код, пытаемся достать информацию об ошибке
            
            return .error(response.extractBaseAPIResponseError())
        }
    }
    
    func mapAsDefaultResponse<T: Decodable>() -> Single<T> {
        return flatMap { response in
            
            // MARK: Если вернулся успешный код - пытаемся замапить реквест
            if let debugString = try? response.mapString(), !(debugString.isEmpty) {
                print("response data: \(debugString.truncated(toLength: 1000))")
            } else {
                print("response data: <empty>")
            }
            
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
    
    func mapAsSberbankResponse() -> Single<SberbankPayProcessResponseData?> {
        return flatMap { response in
            print("response data: \(try response.mapString())")
            
            do {
                let mappedResponse = try response.map(SberbankPayProcessResponseData.self)
                return .just(mappedResponse)
            } catch {
                return .error(NSError.APIWrapperError.baseResponseMappingError)
            }
        }
    }
    
    func mapAsEmptyDataInitializableResponse<T: Decodable & EmptyDataInitializable>() -> Single<T> {
        return flatMap { response in
            // MARK: Если вернулся код 204 (пустой контент), то просто возвращаем пустой контент
            if response.statusCode == 204 {
                print("response data: <empty>")
                return .just(T())
            }
            
            if let debugString = try? response.mapString(), !(debugString.isEmpty) {
                print("response data: \(debugString.truncated(toLength: 1000))")
            } else {
                print("response data: <empty>")
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
    
    func convertNoConnectionError() -> PrimitiveSequence<Trait, Element> {
        return catchError { error in
            let nsError = error as NSError
            
            guard nsError.domain == "Moya.MoyaError",
                nsError.code == 6,
                let afError = nsError.userInfo["NSUnderlyingError"] as? AFError,
                let underlyingError = afError.underlyingError as NSError?,
                underlyingError.domain == "NSURLErrorDomain",
                underlyingError.code == -1009 else {
                throw error
            }

            throw NSError.APIWrapperError.noConnectionError
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
