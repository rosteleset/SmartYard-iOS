//
//  UpdateTokenStateRequest.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct UpdateTokenStateRequest {
    
    let login: String
    let password: String
    let token: String
    let isEnabled: Bool
    
}

extension UpdateTokenStateRequest {
    
    var requestParameters: [String: Any] {
        return [
            "action": "token_intercom",
            "login": login,
            "password": password,
            "token": token,
            "enable": isEnabled ? 1 : 0
        ]
    }
    
}
