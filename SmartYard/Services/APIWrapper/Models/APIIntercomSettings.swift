//
//  APIIntercomSettings.swift
//  SmartYard
//
//  Created by Mad Brains on 21.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct APIIntercomSettings {
    
    let enableDoorCode: Bool?
    let cms: Bool?
    let voip: Bool?
    let autoOpen: Date?
    let whiteRabbit: Bool?
    let paperBill: Bool?
    let disablePlog: Bool?
    let hiddenPlog: Bool?
    let frsDisabled: Bool?
    let allowDoorCode: Bool?
    let doorCode: String?
    
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
            params["whiteRabbit"] = whiteRabbit ? "5" : "0"
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
        
        if let allowDoorCode = allowDoorCode {
            params["allowDoorCode"] = allowDoorCode ? "t" : "f"
        }
        
        if let doorCode = doorCode {
            params["doorCode"] = doorCode
        }
        
        return params
    }
    
}
