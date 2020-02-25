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

struct RegisterPushTokenRequest {
    
    let accessToken: String
    let pushToken: String
    let clientId: String?
    let type: TokenType
    
}

extension RegisterPushTokenRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "pushToken": pushToken,
            "type": type.rawValue
        ]
        
        if let clientId = clientId {
            params["clientId"] = clientId
        }
        
        return params
    }
    
}
