//
//  IssueTypes.swift
//  SmartYard
//
//  Created by Mad Brains on 27.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct Issue {
    
    let issueFields: [String: String]
    let customFields: [String: String]
    let actions: [String]
    
    init(issueType: IssueType) {
        issueFields = [
            "project": issueType.project,
            "summary": issueType.summary,
            "description": issueType.description,
            "type": issueType.type
        ]
        
        customFields = issueType.customFields
        actions = issueType.actions
    }
    
}

enum IssueType {
    
    // экран 19
    case dontRememberAnythingIssue(userInfo: MainUserInfo)
    
    // экран 23
    case confirmAddressByCourierIssue(userInfo: MainUserInfo, lat: String, lon: String)
    
    // экран 24
    case confirmAddressInOfficeIssue(userInfo: MainUserInfo, lat: String, lon: String)
    
    // экран 34.02.03
    case deleteAddressIssue(userInfo: MainUserInfo, lat: String, lon: String, reason: String)
    
    // экран 21
    case servicesUnavailableIssue(userInfo: MainUserInfo, serviceNames: [String], lat: String, lon: String)
    
    // экран 28
    case comeInOfficeMyselfIssue(userInfo: MainUserInfo, lat: String, lon: String, serviceNames: [String])

    // когда нет общедомовых услуг, но есть другие услуги для выбора
    case connectOnlyNonHousesServices(userInfo: MainUserInfo, lat: String, lon: String, serviceNames: [String])
    
    var summary: String {
        let webIssueDescription = "Авто: Заявка с сайта"
        let appCallIssue = "Авто: Звонок с приложения"
        
        switch self {
        case .confirmAddressByCourierIssue, .confirmAddressInOfficeIssue, .servicesUnavailableIssue,
             .comeInOfficeMyselfIssue, .connectOnlyNonHousesServices, .deleteAddressIssue:
            return webIssueDescription
            
        case .dontRememberAnythingIssue:
            return appCallIssue
        }
    }
    
    var description: String {
        switch self {
            
        case .dontRememberAnythingIssue:
            return "Выполнить звонок клиенту для напоминания номера договора и пароля от личного кабинета"
        
        case let .confirmAddressByCourierIssue(userInfo, _, _):
            return userInfo.convertToString() + "\nПодготовить конверт с qr-кодом. Далее заявку отправить курьеру. "
            
        case let .confirmAddressInOfficeIssue(userInfo, _, _):
            return userInfo.convertToString() + "\nКлиент подойдет в офис для получения подтверждения."
        
        case let .deleteAddressIssue(userInfo, _, _, reason):
            return userInfo.convertToString() + "\nУдаление адреса из приложения. Причина: \(reason)"
        
        case let .servicesUnavailableIssue(userInfo, serviceNames, _, _):
            let servicesStr = serviceNames.joined(separator: ", ")
            return userInfo.convertToString() + "\nСписок подключаемых услуг: \(servicesStr)"
            
        case let .comeInOfficeMyselfIssue(userInfo, _, _, serviceNames):
            let servicesStr = serviceNames.joined(separator: ", ")
            let hint = "\nТребуется подтверждение адреса и подключение выбранных услуг"
            return userInfo.convertToString() + "\nСписок подключаемых услуг: \(servicesStr)" + hint
            
        case let .connectOnlyNonHousesServices(userInfo, _, _, serviceNames):
            let servicesStr = serviceNames.joined(separator: ", ")
            let hint = "\nПодключение услуг(и): \(servicesStr).\nВыполнить звонок клиенту и осуществить консультацию"
            return userInfo.convertToString() + hint
        }
    }

    var clientCode: String {
        switch self {
        case .confirmAddressByCourierIssue, .confirmAddressInOfficeIssue, .comeInOfficeMyselfIssue,
             .deleteAddressIssue, .connectOnlyNonHousesServices, .servicesUnavailableIssue:
            return "-1"
            
        case .dontRememberAnythingIssue:
            return "-3"
        }
    }
    
    var actions: [String] {
        let startWorkAction = "Начать работу"
        let callAction = "Позвонить"
        let sendToOfficeAction = "Передать в офис"
        
        switch self {
        case .confirmAddressByCourierIssue, .confirmAddressInOfficeIssue:
            return [startWorkAction, sendToOfficeAction]
            
        case .dontRememberAnythingIssue, .servicesUnavailableIssue,
             .connectOnlyNonHousesServices, .deleteAddressIssue,
             .comeInOfficeMyselfIssue:
            return [startWorkAction, callAction]
        }
    }
    
    var customFields: [String: String] {
        switch self {
        case let .dontRememberAnythingIssue(userInfo):
            return [
                "10011": clientCode,
                "11841": userInfo.phoneNumber,
                "12440": "Приложение"
            ]
            
        case let .confirmAddressByCourierIssue(userInfo, lat, lon):
            return [
                "10011": clientCode,
                "11841": userInfo.phoneNumber,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon,
                "10941": "10581"
            ]
            
        case let .confirmAddressInOfficeIssue(userInfo, lat, lon):
            return [
                "10011": clientCode,
                "11841": userInfo.phoneNumber,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon,
                "10941": "10580"
            ]
            
        case let .deleteAddressIssue(userInfo, lat, lon, _):
            return [
                "10011": clientCode,
                "11841": userInfo.phoneNumber,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon
            ]
            
        case let .servicesUnavailableIssue(userInfo, _, lat, lon):
            return [
                "10011": clientCode,
                "11841": userInfo.phoneNumber,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon
            ]
            
        case let .comeInOfficeMyselfIssue(userInfo, lat, lon, _):
            return [
                "10011": clientCode,
                "11841": userInfo.phoneNumber,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon,
                "10941": "10581"
            ]
            
        case let .connectOnlyNonHousesServices(userInfo, lat, lon, _):
            return [
                "10011": clientCode,
                "11841": userInfo.phoneNumber,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon
            ]
        }
    }
    
    var type: String {
        return "32"
    }

    var project: String {
        return "REM"
    }
    
}
