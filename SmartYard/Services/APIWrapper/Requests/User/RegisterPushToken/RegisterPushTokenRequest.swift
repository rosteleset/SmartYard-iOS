//
//  RegisterTokenRequest.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

enum TokenType: Int {
    
    case fcm
    case apnsRelease
    case apnsDebug
    case fcmRepeating
    
}

struct RegisterPushTokenRequest {
    
    let accessToken: String
    let pushToken: String
    let voipToken: String?
    let clientId: String?
    let production: Bool?
    let type: TokenType
    
}

extension RegisterPushTokenRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "pushToken": pushToken,
            "type": type.rawValue,
            "platform": "ios"
        ]
        
        if let clientId = clientId {
            params["clientId"] = clientId
        }
        
        if let voipToken = voipToken {
            params["voipToken"] = voipToken
        }
        
        if let voipToken = voipToken {
            params["voipToken"] = voipToken
        }
        
        if let production = production {
            params["production"] = production ? "t" : "f"
        }
        
        return params
    }
    
}
