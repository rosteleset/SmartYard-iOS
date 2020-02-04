//
//  RegisterTokenRequest.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

enum TokenType: Int {
    
    case fcm
    case apnsRelease
    case apnsDebug
    
}

struct RegisterTokenRequest {
    
    let accessToken: String
    let pushToken: String
    let clientId: String
    let type: TokenType
    
}

extension RegisterTokenRequest {
    
    var requestParameters: [String: Any] {
        return [
            "pushToken": pushToken,
            "clientId": clientId,
            "type": type.rawValue
        ]
    }
    
}
