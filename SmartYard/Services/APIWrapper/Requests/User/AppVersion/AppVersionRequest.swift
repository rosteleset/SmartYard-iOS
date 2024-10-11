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
        let os = ProcessInfo().operatingSystemVersion
        
        let systemVersion = String(os.majorVersion) + "." + String(os.minorVersion)
        var utsnameInstance = utsname()
        uname(&utsnameInstance)
        let device: String? = withUnsafePointer(to: &utsnameInstance.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        
        return [
            "platform": "ios",
            "system": systemVersion,
            "version": appVersion,
            "device": device ?? "N/A"
        ]
    }
    
}
