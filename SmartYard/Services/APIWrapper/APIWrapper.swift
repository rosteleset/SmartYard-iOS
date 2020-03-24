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
    
    func mapAsEmptyDataInitializable<T: Decodable & EmptyDataInitializable>() -> Single<T> {
        return flatMap { response in
            if response.statusCode == 204 {
                return .just(T())
            }
            
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
    }
    
}

extension PrimitiveSequence where Trait == SingleTrait {
    
    func mapToOptional() -> Single<Element?> {
        return map { $0 }
    }
    
}
