//
//  RequestCodeRequest.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

struct RequestCodeRequest {
    
    let userPhone: String
    
}

extension RequestCodeRequest {
    
    var requestParameters: [String: Any] {
        return [
            "userPhone": userPhone
        ]
    }
    
}
