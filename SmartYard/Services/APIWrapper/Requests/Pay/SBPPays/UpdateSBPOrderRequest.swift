//
//  UpdateSBPOrderRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 25.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit

struct UpdateSBPOrderRequest {
    
    let accessToken: String
    let merchant: Merchant
    let id: String
    let status: Int
    let orderId: String?
    let processed: Date?
    let isTest: Bool
}

extension UpdateSBPOrderRequest {
    
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
            "id": id,
            "status": status,
            "test": isTest ? "t" : "f"
        ]
        
        if let orderId = orderId {
            params["orderId"] = orderId
        }
        
        if let processed = processed {
            params["processed"] = processed.apiString
        }
        
        return params
    }
    
}
