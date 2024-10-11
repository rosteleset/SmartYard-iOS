//
//  AutoPayRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 03.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct AutoPayRequest {
    
    let accessToken: String
    let merchant: Merchant
    let contractName: String
    let summa: Double
    let description: String
    let bindingId: String
    let notifyMethod: CheckSendType
    let email: String?
}

extension AutoPayRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "merchant": {
                switch merchant {
                case .centra:
                    return "centra"
                case .layka:
                    return "layka"
                }
            }(),
            "contractTitle": contractName,
            "summa": summa,
            "description": description,
            "bindingId": bindingId,
            "notifyMethod": notifyMethod.rawValue
        ]
        
        if let email = email {
            params["email"] = email
        }
        return params
    }
    
}
