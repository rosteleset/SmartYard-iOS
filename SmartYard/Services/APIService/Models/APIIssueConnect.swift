//
//  APIListConnect.swift
//  SmartYard
//
//  Created by Mad Brains on 17.03.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct APIIssueConnect: Codable {
    
    let id: String
    let description: String
    
}

extension APIIssueConnect {
    
    var requestParameters: [String: Any] {
        return [
            "id": id,
            "description": description
        ]
    }
    
}
