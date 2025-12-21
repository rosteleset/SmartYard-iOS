//
//  AppVersionRequest.swift
//  SmartYard
//
//  Created by admin on 08.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct AppVersionRequest {
    
    let accessToken: String
    
}

extension AppVersionRequest {
    
    var requestParameters: [String: Any] {
        let appVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ??
        "App version extraction error"
        
        return [
            "platform": "ios",
            "version": appVersion
        ]
    }
    
}
