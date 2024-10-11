//
//  ActivateLimitRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 17.09.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct ActivateLimitRequest {
    
    let accessToken: String
    let contractId: String
}

extension ActivateLimitRequest {
    
    var requestParameters: [String: Any] {
        let params: [String: Any] = [
            "contractId": contractId
        ]
        
        return params
    }
    
}
