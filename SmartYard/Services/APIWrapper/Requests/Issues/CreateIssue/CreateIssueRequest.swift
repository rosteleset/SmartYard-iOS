//
//  CreateIssueRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct CreateIssueRequest: Codable {
    
    let accessToken: String
    let issue: [String: String]
    let customFields: [String: String]
    let actions: [String]
    
    init(accessToken: String, issue: Issue) {
        self.accessToken = accessToken
        self.issue = issue.issueFields
        self.customFields = issue.customFields
        self.actions = issue.actions
    }

}

extension CreateIssueRequest {
    
    var requestParameters: [String: Any] {
        return [
            "issue": issue,
            "customFields": customFields,
            "actions": actions
        ]
    }
    
}
