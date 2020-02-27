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
        var params: [String: Any] = [:]
        
        params["10011"] = code
        params["11841"] = phoneNumber
        params["12440"] = source
        params["10743"] = lat
        params["10744"] = lng
        
        return params
    }
    
}

