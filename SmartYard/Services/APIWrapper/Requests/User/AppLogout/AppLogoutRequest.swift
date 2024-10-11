//
//  AppLogoutRequest.swift
//  SmartYard
//
//  Created by devcentra on 16.02.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct AppLogoutRequest {
    
    let accessToken: String
    
}

extension AppLogoutRequest {
    
    var requestParameters: [String: Any] {
        return [:]
    }
    
}
