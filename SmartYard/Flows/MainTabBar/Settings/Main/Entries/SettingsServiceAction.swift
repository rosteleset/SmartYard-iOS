//
//  SettingsServiceAction.swift
//  SmartYard
//
//  Created by admin on 03/04/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
import Foundation

enum SettingsServiceAction: String {
    
    case changeTariff
    case activateService
    case talkAboutActivation
    
    var templateText: String {
        switch self {
        case .changeTariff: return changeTariffTemplate
        case .activateService: return activateServiceTemplate
        case .talkAboutActivation: return talkAboutActivationTemplate
        }
    }
    
    func request(for serviceType: SettingsServiceType, contractName: String?) -> String {
        return templateText
            .replacingOccurrences(of: "%(X)", with: serviceType.localizedTitle)
            .replacingOccurrences(of: "%(Y)", with: contractName ?? NSLocalizedString("Contract number unknown", comment: ""))
    }
    
    private var changeTariffTemplate: String {
        let text = NSLocalizedString(
            "Hello, I would like to change the tariff for the service \"%(X)\" on the contract \"%(Y)\"",
            comment: ""
        )
        return text
    }
    
    private var activateServiceTemplate: String {
        let text = NSLocalizedString(
            "Hello, I would like to connect the service \"%(X)\" to the contract \"%(Y)\"",
            comment: ""
        )
        return text
    }
    
    private var talkAboutActivationTemplate: String {
        let text = NSLocalizedString(
            "Hello, the \"%(X)\" service is not available at my address, but I want to use it on the \"%(Y)\" contract",
            comment: ""
        )
        return text
    }
    
}
