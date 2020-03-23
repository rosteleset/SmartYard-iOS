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
    
    private let provider: MoyaProvider<APITarget> = {
        let manager = SessionManager()
        manager.retrier = BaseRequestRetrier()
        return MoyaProvider<APITarget>(manager: manager)
    }()
    
    var isReachable: Bool {
        return NetworkReachabilityManager()?.isReachable ?? false
    }
    
    init(accessService: AccessService) {
        self.accessService = accessService
    }
    
    func createInnerCompletionBlock<T: Decodable>(
        from outerBlock: ((Swift.Result<BaseAPIResponse<T>, Error>) -> Void)?
    ) -> Completion {
        return { [weak self] result in
            guard let self = self else {
                return
            }
            
            let convertedResult: Swift.Result<BaseAPIResponse<T>, Error> = {
                switch result {
                case .success(let response): return self.mapResponse(response)
                case .failure(let error): return .failure(error)
                }
            }()
            
            outerBlock?(convertedResult)
        }
    }
    
    func mapResponse<T: Decodable>(_ response: Response) -> Swift.Result<BaseAPIResponse<T>, Error> {
        do {
            return .success(try response.map(BaseAPIResponse<T>.self))
        } catch {
            return .failure(NSError.APIServiceError.mappingError)
        }
    }
    
}
