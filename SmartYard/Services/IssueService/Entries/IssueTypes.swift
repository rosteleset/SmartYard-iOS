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
    
    case unavailableAddressConnectionIssue(userInfo: MainUserInfo, services: [SettingsServiceType], lat: String, lon: String)
    
    case connectSelectedServicesIssue(userInfo: MainUserInfo, services: [SettingsServiceType])
    
    case confirmAddressByCourierIssue(userInfo: MainUserInfo, lat: String, lon: String)
    
    case confirmAddressInOfficeIssue(userInfo: MainUserInfo, lat: String, lon: String)
    
    case deleteAddressIssue(userInfo: MainUserInfo, reason: String)
    
    case activateServiceIssue(userInfo: MainUserInfo, services: [SettingsServiceType])
    
    case changeTariffIssue(clientId: String)
    
    case serviceUnavailableIssue(userInfo: MainUserInfo, service: SettingsServiceType)
    
    case comeInOfficeMyselfIssue(userInfo: MainUserInfo, lat: String, lon: String)
    
    case connectOnlyNonHousesService(userInfo: MainUserInfo, lat: String, lon: String, service: SettingsServiceType)
    
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
            
        case let .comeInOfficeMyselfIssue(userInfo, lat, lon):
            break
            
        case let .connectOnlyNonHousesService(userInfo, lat, lon, service):
            break
        }
    }
    
    var description: String {
        switch self {
        case let .approveAddressIssue(address):
            return "Заявка  на подтверждение адреса \(address)"
            
        case .dontRememberAnythingIssue:
            return "Выполнить звонок клиенту для напоминания номера договора и пароля от личного кабинета"
            
        case let .unavailableAddressConnectionIssue(userInfo, services, _, _):
            return userInfo.convertToString() + "\nСписок подключаемых услуг \(services)"
            
        case let .connectSelectedServicesIssue(userInfo, services):
            let servicesStr = services.map { $0.rawValue }.joined(separator: ", ")
            return userInfo.convertToString() + "\nСписок подключаемых услуг: \(servicesStr)"
        
        case let .confirmAddressByCourierIssue(userInfo, _, _):
            return userInfo.convertToString() + "\nПодготовить конверт с qr-кодом. Далее заявку отправить курьеру. "
            
        case let .confirmAddressInOfficeIssue(userInfo, _, _):
            return userInfo.convertToString() + "\nКлиент подойдет в офис для получения подтверждения."
        
        case let .deleteAddressIssue(userInfo, reason):
            return userInfo.convertToString() + "\nУдаление адреса из приложения. Причина: \(reason)"
        
        case let .activateServiceIssue(userInfo, services):
            let servicesStr = services.map { $0.rawValue }.joined(separator: ", ")
            return userInfo.convertToString() + "\nСписок подключаемых услуг: \(servicesStr)"
        
        case .changeTariffIssue:
            return "Запрос на смену тарифного плана. Выполнить звонок клиенту и осуществить консультацию"
        
        case let .serviceUnavailableIssue(userInfo, services):
            return userInfo.convertToString() + "\nСписок подключаемых услуг: \(services)"
            
        case let .comeInOfficeMyselfIssue(userInfo, lat, lon):
            return ""
            
        case let .connectOnlyNonHousesService(userInfo, lat, lon, service):
            return ""
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
            
        case .comeInOfficeMyselfIssue(let userInfo, let lat, let lon):
            return ""
            
        case .connectOnlyNonHousesService(let userInfo, let lat, let lon, let service):
            return ""
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
            
        case .comeInOfficeMyselfIssue(let userInfo, let lat, let lon):
            return []
            
        case .connectOnlyNonHousesService(let userInfo, let lat, let lon, let service):
            return []
        }
    }
    
    var customFields: [String: String] {
        switch self {
        case .approveAddressIssue(let address):
            return [:]
            
        case .dontRememberAnythingIssue(let userInfo):
            return [
                "10011" : "-3",
                "11841": userInfo.phoneNumber,
                "12440": "Приложение"
            ]
            
        case let .unavailableAddressConnectionIssue(userInfo, _, lat, lon):
            return [
                "10011": "-1",
                "11841": userInfo.phoneNumber,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon
            ]
            
        case .connectSelectedServicesIssue(let userInfo, let services):
            return [:]
            
        case let .confirmAddressByCourierIssue(userInfo, lat, lon):
            return [
                "10011": "-1",
                "11841": userInfo.phoneNumber,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon,
                "10941": "10581"
            ]
            
        case let .confirmAddressInOfficeIssue(userInfo, lat, lon):
            return [
                "10011": "-1",
                "11841": userInfo.phoneNumber,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon,
                "10941": "10580"
            ]
            
        case .deleteAddressIssue(let userInfo, let reason):
            return [:]
            
        case .activateServiceIssue(let userInfo, let services):
            return [:]
            
        case .changeTariffIssue(let clientId):
            return [:]
            
        case .serviceUnavailableIssue(let userInfo, let service):
            return [:]
            
        case .comeInOfficeMyselfIssue(let userInfo, let lat, let lon):
            return [:]
            
        case .connectOnlyNonHousesService(let userInfo, let lat, let lon, let service):
            return [:]
        }
    }
    
    var type: String {
        return "32"
    }

    var project: String {
        return "REM"
    }
    
}
