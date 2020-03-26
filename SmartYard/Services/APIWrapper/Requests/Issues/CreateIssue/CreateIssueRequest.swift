//
//  CreateIssueRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct CreateIssueRequest: Codable {
    
    let accessToken: String
    let issue: APIIssue
    let customFields: [String: String]
    let actions: [String]
    
}

extension CreateIssueRequest {
    
    var requestParameters: [String: Any] {
        return [
            "issue": issue.requestParameters,
            "customFields": customFields,
            "actions": actions
        ]
    }
    
}
