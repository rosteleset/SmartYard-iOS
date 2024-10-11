//
//  CreateSBPOrderRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 25.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct CreateSBPOrderRequest {
    
    let accessToken: String
    let merchant: Merchant
    let contractName: String
    let summa: Double
    let description: String
    let notifyMethod: CheckSendType
    let email: String?
}

extension CreateSBPOrderRequest {
    
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
            "notifyMethod": notifyMethod.rawValue
        ]
        
        if let email = email {
            params["email"] = email
        }
        return params
    }
    
}
