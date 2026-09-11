//
//  GeoCoderRequest.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import Foundation

struct GeoCoderRequest {
    
    let accessToken: String
    let address: String
    
}

extension GeoCoderRequest {
    
    var requestParameters: [String: Any] {
        return [
            "address": address
        ]
    }
    
}
