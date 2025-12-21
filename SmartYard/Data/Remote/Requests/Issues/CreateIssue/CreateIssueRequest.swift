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

struct CreateIssueV2Request: Codable {
    
    let accessToken: String
    let issue: IssueV2
    
    init(accessToken: String, issue: IssueV2) {
        self.accessToken = accessToken
        self.issue = issue
    }
    
}

extension CreateIssueV2Request {
    
    var requestParameters: [String: Any] {
        var parameters: [String: Any] = [:]
        
        parameters["type"] = issue.type?.rawValue
        parameters["userName"] = issue.userName
        parameters["inputAddress"] = issue.inputAddress
        parameters["services"] = issue.services
        parameters["comments"] = issue.comments
        parameters["cameraId"] = issue.cameraId
        parameters["cameraName"] = issue.cameraName
        parameters["fragmentDate"] = issue.fragmentDate
        parameters["fragmentTime"] = issue.fragmentTime
        parameters["fragmentDuration"] = issue.fragmentDuration
        
        return parameters
    }
    
}
