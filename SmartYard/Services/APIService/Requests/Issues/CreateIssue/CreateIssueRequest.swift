//
//  CreateIssueRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct CreateIssueRequest {
    
    let accessToken: String
    let issue: APIIssue
    let customFields: APIIssueCustomField
    let actions: [String]
    
}

extension CreateIssueRequest {
    
    var requestParameters: [String: Any] {
        let params: [String: Any] = [
            "issue": issue.requestParameters,
            "customFields": customFields.requestParameters,
            "actions": actions
        ]
        
        return params
    }
    
}
