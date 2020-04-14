//
//  CommentIssueRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 01.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
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
