//
//  APITarget.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Moya

enum APITarget {
    
    case confirmCode(request: ConfirmCodeRequest)
    case getVerifyedAddresses(request: GetVerifyedAddressesRequest)
    case login(request: LoginRequest)
    case intercomToken(request: IntercomTokenRequest)
    case registerToken(request: RegisterTokenRequest)
    case requestCode(request: RequestCodeRequest)
    
}

extension APITarget: TargetType {
    
    var baseURL: URL {
        return URL(string: "https://dm.lanta.me/api")!
    }
    
    var path: String {
        switch self {
        case .confirmCode: return "user/confirmCode"
        case .getVerifyedAddresses: return "user/getVerifyedAddresses"
        case .login: return "user/login"
        case .intercomToken: return "user/intercomPushToken"
        case .registerToken: return "user/registerPushToken"
        case .requestCode: return "user/requestCode"
        }
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var headers: [String: String]? {
        let defaultHeaders = [
            "Content-type": "application/json"
        ]
        
        let authorization: String? = {
            switch self {
            case .getVerifyedAddresses(let request): return request.accessToken
            case .intercomToken(let request): return request.accessToken
            case .registerToken(let request): return request.accessToken
            default: return nil
            }
        }()
        
        guard let token = authorization else {
            return defaultHeaders
        }
        
        return defaultHeaders.merging(["Authorization": "Bearer " + token]) { _, new in new }
    }
    
    var task: Task {
        return .requestParameters(parameters: requestParameters, encoding: JSONEncoding.default)
    }
    
    var requestParameters: [String: Any] {
        switch self {
        case .confirmCode(let request): return request.requestParameters
        case .getVerifyedAddresses(let request): return request.requestParameters
        case .login(let request): return request.requestParameters
        case .intercomToken(let request): return request.requestParameters
        case .registerToken(let request): return request.requestParameters
        case .requestCode(let request): return request.requestParameters
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
}
