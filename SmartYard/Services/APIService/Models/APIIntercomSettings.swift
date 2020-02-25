//
//  APIIntercomSettings.swift
//  SmartYard
//
//  Created by Mad Brains on 21.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct APIIntercomSettings {
    
    let enableDoorCode: Bool?
    let cms: String?
    let voip: String?
    let autoOpen: String?
    let whiteRabbit: String?
    
}

extension APIIntercomSettings {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [:]
        
        if let enableDoorCode = enableDoorCode {
            params["enableDoorCode"] = enableDoorCode ? "t" : "f"
        }
        
        if let cms = cms {
            params["CMS"] = cms
        }
        
        if let voip = voip {
            params["VoIP"] = voip
        }
        
        if let autoOpen = autoOpen {
            params["autoOpen"] = autoOpen
        }
        
        if let whiteRabbit = whiteRabbit {
            params["whiteRabbit"] = whiteRabbit
        }
        
        return params
    }
    
}
