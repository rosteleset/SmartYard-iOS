//
//  IssueTypes.swift
//  SmartYard
//
//  Created by Mad Brains on 27.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable line_length

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
    case deleteAddressIssue(userInfo: MainUserInfo, lat: String, lon: String, clientId: String, reason: String)
    
    // экран 21
    case servicesUnavailableIssue(userInfo: MainUserInfo, serviceNames: [String], lat: String, lon: String)
    
    // экран 28
    case comeInOfficeMyselfIssue(userInfo: MainUserInfo, lat: String, lon: String, serviceNames: [String])

    // когда нет общедомовых услуг, но есть другие услуги для выбора
    case connectOnlyNonHousesServices(userInfo: MainUserInfo, lat: String, lon: String, serviceNames: [String])
    
    // экран 35 (Меню)
    case orderCallback
    
    // экран 37 Запрос записи
    case requestRec(camera: CityCameraObject, date: Date, duration: Int, notes: String)
    
    var summary: String {
        let webIssueDescription = "Авто: Заявка с сайта"
        let appCallIssue = "Авто: Звонок с приложения"
        
        switch self {
        case .confirmAddressByCourierIssue, .confirmAddressInOfficeIssue, .servicesUnavailableIssue,
             .comeInOfficeMyselfIssue, .connectOnlyNonHousesServices, .deleteAddressIssue:
            return webIssueDescription
            
        case .dontRememberAnythingIssue, .orderCallback:
            return appCallIssue
        case .requestRec:
            return "Авто: Запрос на получение видеофрагмента с архива"
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
        
        case let .deleteAddressIssue(userInfo, _, _, cliendId, reason):
            return userInfo.convertToString() + "\ncontractId-" + cliendId + "-\nУдаление адреса из приложения. Причина: \(reason)"
        
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
            
        case .orderCallback:
            return "Выполнить звонок клиенту по запросу из приложения"
            
        case let .requestRec(camera, date, duration, notes):
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy HH:mm"
            formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
            formatter.locale = Calendar.novokuznetskCalendar.locale
            let result = """
Обработать запрос на добавление видеофрагмента из архива видовой видеокамеры \(camera.name) (id=\(camera.id)) по парамертам:
время: \(formatter.string(from: date)),
продолжительность фрагмента: \(duration) мин.
комментарии пользователя: \(notes).
"""
            return result
        }
    }

    var clientCode: String {
        switch self {
        case .confirmAddressByCourierIssue, .confirmAddressInOfficeIssue, .comeInOfficeMyselfIssue,
             .deleteAddressIssue, .connectOnlyNonHousesServices, .servicesUnavailableIssue:
            return "-1"
            
        case .dontRememberAnythingIssue, .orderCallback:
            return "-3"
        case .requestRec:
            return "-5"
        }
    }
    
    var actions: [String] {
        let startWorkAction = "Начать работу"
        let callAction = "Позвонить"
        let sendToOfficeAction = "Передать в офис"
        let sendToManagerCCTV = "Менеджеру ВН"
        
        switch self {
        case .confirmAddressByCourierIssue, .confirmAddressInOfficeIssue:
            return [startWorkAction, sendToOfficeAction]
            
        case .dontRememberAnythingIssue, .servicesUnavailableIssue,
             .connectOnlyNonHousesServices, .deleteAddressIssue,
             .comeInOfficeMyselfIssue, .orderCallback:
            return [startWorkAction, callAction]
        case .requestRec:
            return [startWorkAction, sendToManagerCCTV]
        }
    }
    
    var customFields: [String: String] {
        let formatter = DateFormatter()
        formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
        formatter.locale = Calendar.novokuznetskCalendar.locale
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        
        let now = formatter.string(from: Date())
        
        switch self {
        case .dontRememberAnythingIssue:
            return [
                "10011": clientCode,
                "11840": now,
                "12440": "Приложение"
            ]
            
        case .orderCallback, .requestRec:
            return [
                "10011": clientCode,
                "11840": now,
                "12440": "Приложение"
            ]
            
        case let .confirmAddressByCourierIssue(_, lat, lon):
            return [
                "10011": clientCode,
                "11840": now,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon,
                "10941": "10581"
            ]
            
        case let .confirmAddressInOfficeIssue(_, lat, lon):
            return [
                "10011": clientCode,
                "11840": now,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon,
                "10941": "10580"
            ]
            
        case let .deleteAddressIssue(_, lat, lon, _, _):
            return [
                "10011": clientCode,
                "11840": now,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon
            ]
            
        case let .servicesUnavailableIssue(_, _, lat, lon):
            return [
                "10011": clientCode,
                "11840": now,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon
            ]
            
        case let .comeInOfficeMyselfIssue(_, lat, lon, _):
            return [
                "10011": clientCode,
                "11840": now,
                "12440": "Приложение",
                "10743": lat,
                "10744": lon,
                "10941": "10581"
            ]
            
        case let .connectOnlyNonHousesServices(_, lat, lon, _):
            return [
                "10011": clientCode,
                "11840": now,
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
// swiftlint:enable line_length
