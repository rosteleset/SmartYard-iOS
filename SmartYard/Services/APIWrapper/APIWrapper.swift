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
