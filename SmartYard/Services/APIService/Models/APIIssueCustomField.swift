//
//  APIIssueCustomField.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct APIIssueCustomField {
    
    let code: String
    let phoneNumber: String
    let source: String
    let lat: String
    let lng: String
    
    var requestParameters: [String: Any] {
        return [
            "10011": code,
            "11841": phoneNumber,
            "12440": source,
            "10743": lat,
            "10744": lng
        ]
    }
    
}

