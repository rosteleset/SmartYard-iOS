//
//  DetailRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 13.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct DetailRequest {
    
    let accessToken: String
    let id: String
    let to: String?
    let from: String?
}

extension DetailRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "id": id
        ]
        
        if let to = to {
            params["to"] = to
        }

        if let from = from {
            params["from"] = from
        }

        return params
    }
    
}
