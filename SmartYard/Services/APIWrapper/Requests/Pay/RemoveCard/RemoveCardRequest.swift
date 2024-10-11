//
//  RemoveCardRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 03.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct RemoveCardRequest {
    
    let accessToken: String
    let merchant: Merchant
    let bindingId: String
}

extension RemoveCardRequest {
    
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
