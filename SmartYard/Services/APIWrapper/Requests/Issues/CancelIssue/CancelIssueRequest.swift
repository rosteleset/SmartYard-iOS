//
//  CancelIssueRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 01.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct CancelIssueRequest: Codable {
    
    let accessToken: String
    let key: String
    let action: String
    let customFields: [String: String]?
    
}

extension CancelIssueRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "key": key,
            "action": action
        ]
        
        if let customFields = customFields {
            params["customFields"] = customFields
        }

        return params
    }
    
}
