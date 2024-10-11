//
//  GetCardsRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 03.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct GetCardsRequest {
    
    let accessToken: String
    let contractName: String
}

extension GetCardsRequest {
    
    var requestParameters: [String: Any] {
        let params: [String: Any] = [
            "contractName": contractName
        ]
        
        return params
    }
    
}
