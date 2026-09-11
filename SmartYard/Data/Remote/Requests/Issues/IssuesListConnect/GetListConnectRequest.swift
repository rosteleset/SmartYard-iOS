//
//  GetListConnect.swift
//  SmartYard
//
//  Created by Mad Brains on 27.02.2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import Foundation

struct GetListConnectRequest {
    
    let accessToken: String
    let forceRefresh: Bool
}

extension GetListConnectRequest {
    
    var requestParameters: [String: Any] {
        return [:]
    }
    
}

struct GetListConnectV2Request {
    
    let accessToken: String
    let forceRefresh: Bool
}

extension GetListConnectV2Request {
    
    var requestParameters: [String: Any] {
        return [:]
    }
    
}
