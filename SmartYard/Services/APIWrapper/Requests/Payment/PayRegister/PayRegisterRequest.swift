//
//  PayRegisterRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 14.03.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

struct PayRegisterRequest {
    let orderNumber: String
    let amount: String
}

extension PayRegisterRequest {
    
    var requestParameters: [String: Any] {
        return [
            "orderNumber": orderNumber,
            "amount": amount
        ]
    }
    
}
