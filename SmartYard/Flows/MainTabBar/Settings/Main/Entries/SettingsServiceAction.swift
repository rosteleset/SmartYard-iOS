//
//  SettingsServiceAction.swift
//  SmartYard
//
//  Created by admin on 03/04/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

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
            .replacingOccurrences(of: "%(Y)", with: contractName ?? "Номер договора неизвестен")
    }
    
    private var changeTariffTemplate: String {
        return "Здравствуйте, я бы хотел изменить тариф для услуги \"%(X)\" на договоре \"%(Y)\""
    }
    
    private var activateServiceTemplate: String {
        return "Здравствуйте, я бы хотел подключить услугу \"%(X)\" на договор \"%(Y)\""
    }
    
    private var talkAboutActivationTemplate: String {
        return "Здравствуйте, услуга \"%(X)\" недоступна по моему адресу, но я хочу пользоваться ей на договоре \"%(Y)\""
    }
    
}
