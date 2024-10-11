//
//  GetContractsRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 31.05.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct GetContractsRequest {
    
    let accessToken: String
    let forceRefresh: Bool
}

extension GetContractsRequest {
    
    var requestParameters: [String: Any] {
        return [:]
    }
    
}
