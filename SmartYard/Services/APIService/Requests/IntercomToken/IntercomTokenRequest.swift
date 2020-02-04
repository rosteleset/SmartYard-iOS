//
//  IntercomTokenRequest.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

enum TokenState: String {
    
    case on
    case off
    
}

struct IntercomTokenRequest {
    
    let accessToken: String
    let pushToken: String
    let clientId: String
    let state: TokenState?
    
}

extension IntercomTokenRequest {
    
    var requestParameters: [String: Any] {
        var params = [
            "pushToken": pushToken,
            "clientId": clientId
        ]
        
        if let state = state {
            params["state"] = state.rawValue
        }
        
        return params
    }
    
}
