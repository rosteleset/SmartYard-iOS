//
//  SendDetailRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 13.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct SendDetailRequest {
    
    let accessToken: String
    let id: String
    let contract: String
    let to: String
    let from: String
    let mail: String
}

extension SendDetailRequest {
    
    var requestParameters: [String: Any] {
        let params: [String: Any] = [
            "id": id,
            "contract": contract,
            "to": to,
            "from": from,
            "mail": mail
        ]
        
        return params
    }
    
}
