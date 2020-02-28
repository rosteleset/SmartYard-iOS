//
//  IssueTypes.swift
//  SmartYard
//
//  Created by Mad Brains on 27.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

enum IssueTypes {
    
    case approveAddressIssue(address: String)
    
    case dontRememberAnythingIssue
    
    case unavailableAddressConnectionIssue(
        fullName: String,
        phone: String,
        address: String,
        services: [SettingsServiceType]
    )
    
    case activateSelectedServicesIssue(
        fullName: String,
        phone: String,
        address: String,
        services: [SettingsServiceType]
    )
    
    case confirmAddressByCourierIssue(
        fullName: String,
        phone: String,
        address: String
    )
    
    case confirmAddressInOfficeIssue(
        fullName: String,
        phone: String,
        address: String
    )
    
    case deleteAddressIssue(
        fullName: String,
        clientId: String?,
        phone: String,
        address: String,
        reason: String
    )
    
    case activateServiceIssue(
        fullName: String,
        clientId: String?,
        phone: String,
        address: String,
        services: [SettingsServiceType]
    )
    
    case changeTariffIssue(clientId: String)
    
    case serviceUnavailableIssue(
        fullName: String,
        clientId: String,
        phone: String,
        address: String,
        service: SettingsServiceType
    )
    
    var summary: String {
        let webIssueDescription = "Авто: Заявка с сайта"
        let appCallIssue = "Авто: Звонок с приложения"
        let resaleIssue = "Авто: Допродажа"
        let deleteAddressIssue = "Авто: Удаление адреса из приложения"
        
        switch self {
        case .approveAddressIssue, .unavailableAddressConnectionIssue,
             .activateSelectedServicesIssue, .confirmAddressByCourierIssue,
             .confirmAddressInOfficeIssue, .serviceUnavailableIssue:
            return webIssueDescription
            
        case .dontRememberAnythingIssue:
            return appCallIssue
            
        case .deleteAddressIssue:
            return deleteAddressIssue
            
        case .activateServiceIssue, .changeTariffIssue:
            return resaleIssue
        }
    }
    
    var description: String {
        switch self {
        case let .approveAddressIssue(address):
            return "Заявка  на подтверждение адреса \(address)"
            
        case .dontRememberAnythingIssue:
            return "Выполнить звонок клиенту для напоминания номера договора и пароля от личного кабинета"
            
        case let .unavailableAddressConnectionIssue(fullName, phone, address, services):
            let mainInfo = getMainInfo(name: fullName, phone: phone, address: address)
            return mainInfo + "\nСписок подключаемых услуг: \(services)"
        
        case let .activateSelectedServicesIssue(fullName, phone, address, services):
            let mainInfo = getMainInfo(name: fullName, phone: phone, address: address)
            return mainInfo + "\nСписок подключаемых услуг: \(services)"
        
        case let .confirmAddressByCourierIssue(fullName, phone, address):
            let mainInfo = getMainInfo(name: fullName, phone: phone, address: address)
            return mainInfo + "\nДоставить клиенту конверт для подтверждения адреса."
        
        case let .confirmAddressInOfficeIssue(fullName, phone, address):
            let mainInfo = getMainInfo(name: fullName, phone: phone, address: address)
            return mainInfo + "\nКлиент подойдет в офис для получения подтверждения. Ждите!"
        
        case let .deleteAddressIssue(fullName, _, phone, address, reason):
            let mainInfo = getMainInfo(name: fullName, phone: phone, address: address)
            return mainInfo + "\nУдаление адреса из приложения. Причина: \(reason)"
        
        case let .activateServiceIssue(fullName, _, phone, address, services):
            let mainInfo = getMainInfo(name: fullName, phone: phone, address: address)
            return mainInfo + "\nСписок подключаемых услуг: \(services)"
        
        case .changeTariffIssue:
            return "Запрос на смену тарифного плана. Выполнить звонок клиенту и осуществить консультацию"
        
        case let .serviceUnavailableIssue(fullName, _, phone, address, services):
            let mainInfo = getMainInfo(name: fullName, phone: phone, address: address)
            return mainInfo + "\nСписок подключаемых услуг: \(services)"
        }
    }
    
    var clinetCode: String {
        switch self {
        case .approveAddressIssue, .unavailableAddressConnectionIssue,
             .activateSelectedServicesIssue, .confirmAddressByCourierIssue,
             .confirmAddressInOfficeIssue:
            return "-1"
            
        case .dontRememberAnythingIssue:
            return "-3"
            
        case let .deleteAddressIssue(_, clientId, _, _, _), let .activateServiceIssue(_, clientId, _, _, _):
            return clientId ?? "-1"
            
        case let .changeTariffIssue(clientId), let .serviceUnavailableIssue(_, clientId, _, _, _):
            return clientId
        }
    }
    
    
    
    private func getMainInfo(name: String, phone: String, address: String) -> String {
        return "ФИО: \(name)\nТелефон: \(phone)\nАдрес, введённый пользователем: \(address)"
    }
    
}
