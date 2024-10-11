//
//  SetParentControlRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 10.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct SetParentControlRequest {
    
    let accessToken: String
    let clientId: String
}

extension SetParentControlRequest {
    
    var requestParameters: [String: Any] {
        let params: [String: Any] = [
            "clientId": clientId
        ]
        return params
    }
    
}
