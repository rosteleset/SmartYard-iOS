//
//  CheckTokenStateRequest.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct CheckTokenStateRequest {
    
    let login: String
    let password: String
    let token: String
    
}

extension CheckTokenStateRequest {
    
    var requestParameters: [String: Any] {
        return [
            "action": "token_intercom",
            "login": login,
            "password": password,
            "token": token
        ]
    }
    
}
