//
//  CommentIssueRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 01.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct CommentIssueRequest: Codable {
    
    let accessToken: String
    let key: String
    let comment: String
    
}

extension CommentIssueRequest {
    
    var requestParameters: [String: Any] {
        return [
            "key": key,
            "comment": comment
        ]
    }
    
}

struct CommentIssueV2Request: Codable {
    
    let accessToken: String
    let key: String
    let comment: String
    
}

extension CommentIssueV2Request {
    
    var requestParameters: [String: Any] {
        return [
            "key": key,
            "comment": comment
        ]
    }
    
}
