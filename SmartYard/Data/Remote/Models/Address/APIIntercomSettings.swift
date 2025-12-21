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
    let lprsDisabled: Bool?
    
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
        
        if let lprsDisabled = lprsDisabled {
            params["LPRSDisabled"] = lprsDisabled ? "t" : "f"
        }
        
        return params
    }
    
}

extension APIIntercomSettings {
    
    static func create(
        enableDoorCode: Bool? = nil,
        cms: Bool? = nil,
        voip: Bool? = nil,
        autoOpen: Date? = nil,
        whiteRabbit: Bool? = nil,
        paperBill: Bool? = nil,
        disablePlog: Bool? = nil,
        hiddenPlog: Bool? = nil,
        frsDisabled: Bool? = nil,
        lprsDisabled: Bool? = nil
    ) -> APIIntercomSettings? {
        return APIIntercomSettings(
            enableDoorCode: enableDoorCode,
            cms: cms,
            voip: voip,
            autoOpen: autoOpen,
            whiteRabbit: whiteRabbit,
            paperBill: paperBill,
            disablePlog: disablePlog,
            hiddenPlog: hiddenPlog,
            frsDisabled: frsDisabled,
            lprsDisabled: lprsDisabled
        )
    }
    
}
