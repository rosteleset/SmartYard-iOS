//
//  IssueTypes.swift
//  SmartYard
//
//  Created by Mad Brains on 27.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

enum IssueType {
    
    case approveAddressIssue(address: String)
    
    case dontRememberAnythingIssue(userInfo: MainUserInfo)
    
    case unavailableAddressConnectionIssue(userInfo: MainUserInfo, services: [SettingsServiceType])
    
    case connectSelectedServicesIssue(userInfo: MainUserInfo, services: [SettingsServiceType])
    
    case confirmAddressByCourierIssue(userInfo: MainUserInfo)
    
    case confirmAddressInOfficeIssue(userInfo: MainUserInfo)
    
    case deleteAddressIssue(userInfo: MainUserInfo, reason: String)
    
    case activateServiceIssue(userInfo: MainUserInfo, services: [SettingsServiceType])
    
    case changeTariffIssue(clientId: String)
    
    case serviceUnavailableIssue(userInfo: MainUserInfo, service: SettingsServiceType)
    
    var summary: String {
        let webIssueDescription = "Авто: Заявка с сайта"
        let appCallIssue = "Авто: Звонок с приложения"
        let resaleIssue = "Авто: Допродажа"
        let deleteAddressIssue = "Авто: Удаление адреса из приложения"
        
        switch self {
        case .approveAddressIssue, .unavailableAddressConnectionIssue,
             .connectSelectedServicesIssue, .confirmAddressByCourierIssue,
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
            
        case let .unavailableAddressConnectionIssue(userInfo, services),
             let .connectSelectedServicesIssue(userInfo, services):
            let servicesStr = services.map { $0.rawValue }.joined(separator: ", ")
            return userInfo.convertToString() + "\nСписок подключаемых услуг: \(servicesStr)"
        
        case let .confirmAddressByCourierIssue(userInfo):
            return userInfo.convertToString() + "\nДоставить клиенту конверт для подтверждения адреса."
        
        case let .confirmAddressInOfficeIssue(userInfo):
            return userInfo.convertToString() + "\nКлиент подойдет в офис для получения подтверждения. Ждите!"
        
        case let .deleteAddressIssue(userInfo, reason):
            return userInfo.convertToString() + "\nУдаление адреса из приложения. Причина: \(reason)"
        
        case let .activateServiceIssue(userInfo, services):
            let servicesStr = services.map { $0.rawValue }.joined(separator: ", ")
            return userInfo.convertToString() + "\nСписок подключаемых услуг: \(servicesStr)"
        
        case .changeTariffIssue:
            return "Запрос на смену тарифного плана. Выполнить звонок клиенту и осуществить консультацию"
        
        case let .serviceUnavailableIssue(userInfo, services):
            return userInfo.convertToString() + "\nСписок подключаемых услуг: \(services)"
        }
    }
    
    var clientCode: String {
        switch self {
        case .approveAddressIssue, .unavailableAddressConnectionIssue,
             .connectSelectedServicesIssue, .confirmAddressByCourierIssue,
             .confirmAddressInOfficeIssue:
            return "-1"
            
        case .dontRememberAnythingIssue:
            return "-3"
            
        case let .deleteAddressIssue(userInfo, _),
             let .activateServiceIssue(userInfo, _):
            return userInfo.clientId ?? "-1"
            
        case let .changeTariffIssue(clientId):
            return clientId
            
        case let .serviceUnavailableIssue(userInfo, _):
            return userInfo.clientId ?? ""
        }
    }
    
    var actions: [String] {
        let startWorkAction = "Начать работу"
        let callAction = "Позвонить"
        let sendToOfficeAction = "Передать в офис"
        
        switch self {
        case .approveAddressIssue, .confirmAddressByCourierIssue,
             .confirmAddressInOfficeIssue, .deleteAddressIssue:
            return [startWorkAction, sendToOfficeAction]
            
        case .dontRememberAnythingIssue, .unavailableAddressConnectionIssue,
             .connectSelectedServicesIssue, .changeTariffIssue,
             .activateServiceIssue, .serviceUnavailableIssue:
            return [startWorkAction, callAction]
        }
    }

}
