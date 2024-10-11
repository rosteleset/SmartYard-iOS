//
//  NewPayRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 03.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct NewPayRequest {
    
    let accessToken: String
    let merchant: Merchant
    let contractName: String
    let summa: Double
    let description: String
    let returnUrl: String
}

extension NewPayRequest {
    
    var requestParameters: [String: Any] {
        let params: [String: Any] = [
            "merchant": {
                switch merchant {
                case .centra:
                    return "centra"
                case .layka:
                    return "layka"
                }
            }(),
            "contract_title": contractName,
            "summa": summa,
            "description": description,
            "returnUrl": returnUrl
        ]
        
        return params
    }
    
}
