//
//  GetPaymentsListRequest.swift
//  SmartYard
//
//  Created by admin on 25/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

struct GetPaymentsListRequest {
    
    let accessToken: String
    let forceRefresh: Bool
}

extension GetPaymentsListRequest {
    
    var requestParameters: [String: Any] {
        return [:]
    }
    
}
