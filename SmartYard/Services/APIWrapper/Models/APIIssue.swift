//
//  APIIssue.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct APIIssue: Codable {
    
    let project: String
    let summary: String
    let description: String
    let type: String

}

extension APIIssue {
    
    var requestParameters: [String: Any] {
        return [
            "project": project,
            "summary": summary,
            "description": description,
            "type": type
        ]
    }
    
}
