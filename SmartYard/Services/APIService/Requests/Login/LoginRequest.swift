//
//  LoginRequest.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct LoginRequest {
    
    let login: String
    let password: String
    
}

extension LoginRequest {
    
    var requestParameters: [String: Any] {
        return [
            "login": login,
            "password": password
        ]
    }
    
}
