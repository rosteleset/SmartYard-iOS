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
            .replacingOccurrences(of: "%(Y)", with: contractName ?? L10n.Services.Request.unknownContractNumber)
    }
    
    private var changeTariffTemplate: String {
        let text = L10n.Settings.Main.ServiceAction.changeTariffTemplate
        return text
    }
    
    private var activateServiceTemplate: String {
        let text = L10n.Settings.Main.ServiceAction.activateServiceTemplate
        return text
    }
    
    private var talkAboutActivationTemplate: String {
        let text = L10n.Settings.Main.ServiceAction.talkAboutActivationTemplate
        return text
    }
    
}
