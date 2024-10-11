//
//  YooKassaNewPayRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 16.08.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct YooKassaNewPayRequest {
    
    let accessToken: String
    let merchant: Merchant
    let paymentToken: String
    let contractName: String
    let summa: Double
    let description: String
    let isCardSave: Bool
    let isAutopay: Bool
    let notifyMethod: CheckSendType
    let email: String?
}

extension YooKassaNewPayRequest {
    
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
            "token": paymentToken,
            "contractTitle": contractName,
            "summa": summa,
            "description": description,
            "notifyMethod": notifyMethod.rawValue,
            "saveCard": isCardSave,
            "saveAuto": isAutopay
        ]
        
        if let email = email {
            params["email"] = email
        }
        
        return params
    }
    
}
