//
//  APIIssue.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
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
        let params: [String: Any] = [
            "project": project,
            "summary": summary,
            "description": description,
            "type": type
        ]
        
        return params
    }
    
}
