//
//  SendTokenRequest.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

enum TokenType: Int {
    
    case fcm
    case apnsRelease
    case apnsDebug
    
}

struct SendTokenRequest {
    
    let login: String
    let password: String
    let token: String
    let tokenType: TokenType
    
}

extension SendTokenRequest {
    
    var requestParameters: [String: Any] {
        return [
            "action": "token_register",
            "login": login,
            "password": password,
            "token": token,
            "type": tokenType.rawValue
        ]
    }
    
}
