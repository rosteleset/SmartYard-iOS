//
//  AddAutopayRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 25.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct AddAutopayRequest {
    
    let accessToken: String
    let merchant: Merchant
    let bindingId: String
}

extension AddAutopayRequest {
    
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
            "bindingId": bindingId
        ]
        
        return params
    }
    
}
