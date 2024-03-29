//
//  CancelIssueRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 01.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct ActionIssueRequest: Codable {
    
    let accessToken: String
    let key: String
    let action: String
    let customFields: [[String: String]]?
    
}

extension ActionIssueRequest {
    
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

struct ActionIssueV2Request: Codable {
    
    let accessToken: String
    let key: String
    let action: String
    let deliveryType: String?
    
    init(accessToken: String, key: String, action: ActionTypeIssue, deliveryType: IssueDeliveryType? = nil) {
        self.accessToken = accessToken
        self.key = key
        self.action = action.rawValue
        self.deliveryType = deliveryType?.rawValue
    }
    
}

extension ActionIssueV2Request {

    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "key": key,
            "action": action
        ]
        
        if let deliveryType = deliveryType {
            params["customFields"] = deliveryType
        }

        return params
    }
}
