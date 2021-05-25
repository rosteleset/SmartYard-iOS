//
//  APIIntercomSettings.swift
//  SmartYard
//
//  Created by Mad Brains on 21.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct APIIntercomSettings {
    
    let enableDoorCode: Bool?
    let cms: Bool?
    let voip: Bool?
    let autoOpen: Date?
    let whiteRabbit: String?
    let paperBill: Bool?
    let disablePlog: Bool?
    let hiddenPlog: Bool?
    let frsDisabled: Bool?
    
}

extension APIIntercomSettings {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [:]
        
        if let enableDoorCode = enableDoorCode {
            params["enableDoorCode"] = enableDoorCode ? "t" : "f"
        }
        
        if let cms = cms {
            params["CMS"] = cms ? "t" : "f"
        }
        
        if let voip = voip {
            params["VoIP"] = voip ? "t" : "f"
        }
        
        if let autoOpen = autoOpen {
            params["autoOpen"] = autoOpen.apiString
        }
        
        if let whiteRabbit = whiteRabbit {
            params["whiteRabbit"] = whiteRabbit
        }
        
        if let paperBill = paperBill {
            params["paperBill"] = paperBill ? "t" : "f"
        }
        
        if let disablePlog = disablePlog {
            params["disablePlog"] = disablePlog ? "t" : "f"
        }
        
        if let hiddenPlog = hiddenPlog {
            params["hiddenPlog"] = hiddenPlog ? "t" : "f"
        }
        
        if let frsDisabled = frsDisabled {
            params["FRSDisabled"] = frsDisabled ? "t" : "f"
        }
        
        return params
    }
    
}
