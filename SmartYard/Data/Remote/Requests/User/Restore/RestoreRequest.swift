//
//  RestoreRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 18.03.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct RestoreRequest {
    
    let accessToken: String
    let contract: String
    let contactId: String?
    let code: String?
    let comment: String?
    let notification: Bool?
    
}

extension RestoreRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "contract": contract
        ]
        
        if let contactId = contactId {
            params["contact_id"] = contactId
        }
        
        if let code = code {
            params["code"] = code
        }
        
        if let comment = comment {
            params["comment"] = comment
        }
        
        if let notification = notification {
            params["notification"] = notification ? "t" : "f"
        }
        
        return params
    }
    
}
