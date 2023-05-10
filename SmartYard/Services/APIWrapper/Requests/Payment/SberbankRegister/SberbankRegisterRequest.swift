//
//  SberbankRegisterRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 14.03.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

struct SberbankRegisterRequest {
    let accessToken: String // TODO
    let userName: String
    let password: String
    let orderNumber: String
    let amount: String
    let returnUrl: String
    let failUrl: String
}

extension SberbankRegisterRequest {
    
    var requestParameters: [String: Any] {
        return [
            "userName": userName,
            "password": password,
            "orderNumber": orderNumber,
            "amount": amount,
            "returnUrl": returnUrl,
            "failUrl": failUrl
        ]
    }
    
}
