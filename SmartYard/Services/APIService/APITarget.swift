//
//  APITarget.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Moya

enum APITarget {
    
    case sendToken(request: SendTokenRequest)
    case updateTokenState(request: UpdateTokenStateRequest)
    case checkTokenState(request: CheckTokenStateRequest)
    
}

extension APITarget: TargetType {
    
    var baseURL: URL {
        return URL(string: "https://dm.lanta.me/api")!
    }
    
    var path: String {
        return ""
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var headers: [String: String]? {
        return nil
    }
    
    var task: Task {
        return .requestParameters(parameters: requestParameters, encoding: URLEncoding.queryString)
    }
    
    var requestParameters: [String: Any] {
        switch self {
        case let .sendToken(request): return request.requestParameters
        case let .updateTokenState(request): return request.requestParameters
        case let .checkTokenState(request): return request.requestParameters
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
}
