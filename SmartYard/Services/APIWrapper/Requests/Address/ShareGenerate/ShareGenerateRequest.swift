//
//  ShareGenerateRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 18.04.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct ShareGenerateRequest {
    
    let accessToken: String
    let houseId: Int
    let flat: Int
    let domophoneId: String
    let timeExpire: Int?
    let count: Int?
    
}

extension ShareGenerateRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "houseId": houseId,
            "flat": flat,
            "domophoneId": domophoneId
        ]
        
        if let timeExpire = timeExpire {
            params["timeExpire"] = timeExpire
        }
        
        if let count = count {
            params["count"] = count
        }
        
        return params
    }
    
}
