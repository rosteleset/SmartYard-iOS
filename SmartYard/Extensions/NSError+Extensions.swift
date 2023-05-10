//
//  NSError+Extensions.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

// MARK: Generic Errors

extension NSError {
    
    enum GenericError {
        
        private static let domain = "GenericError"
        
        static let selfIsDeadError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: "self уничтожился"]
            
            return NSError(
                domain: domain,
                code: 1001,
                userInfo: errorUserInfo
            )
        }()
        
        static let unknownError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: "Неизвестная ошибка"]
            
            return NSError(
                domain: domain,
                code: 1002,
                userInfo: errorUserInfo
            )
        }()
        
        /// Не удалось настроить камеру
        static let cameraSetupFailed = NSError(
            domain: domain,
            code: 1003,
            userInfo: [NSLocalizedDescriptionKey: "Не удалось настроить камеру"]
        )
    }
    
}

// MARK: APIWrapper Errors

extension NSError {
    
    enum APIWrapperError {
        
        static let domain = "APIWrapperError"
        
        static let baseResponseMappingError: NSError = {
            let description = "Не удалось представить ответ сервера в виде базовой модели"
            
            return NSError(
                domain: domain,
                code: 3100,
                userInfo: [NSLocalizedDescriptionKey: description]
            )
        }()
        
        static let noDataError: NSError = {
            let description = "Ошибка маппинга поля Data, либо же оно отсутствует при коде отличном от 204"

            return NSError(
                domain: domain,
                code: 3101,
                userInfo: [NSLocalizedDescriptionKey: description]
            )
        }()
        
        static let noConnectionError = NSError(
            domain: domain,
            code: 3102,
            userInfo: [NSLocalizedDescriptionKey: "Нет соединения"]
        )
        
        static let noImageBase64Converted = NSError(
            domain: domain,
            code: 3102,
            userInfo: [NSLocalizedDescriptionKey: "Изображение не может быть отправлено"]
        )
        
        static func codeIsNotSuccessful(_ code: Int) -> NSError {
            return NSError(
                domain: domain,
                code: code,
                userInfo: [NSLocalizedDescriptionKey: "В ходе выполнения запроса произошла ошибка \(code)"]
            )
        }
        
        static func codeIsNotSuccessfulExtended(code: Int, message: String) -> NSError {
            return NSError(
                domain: domain,
                code: code,
                userInfo: [NSLocalizedDescriptionKey: "\(message) (\(code))"]
            )
        }
        
        static let accessTokenMissingError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: "Не найден access token. Выполнить запрос невозможно"]
            
            return NSError(
                domain: domain,
                code: 3001,
                userInfo: errorUserInfo
            )
        }()
        
        static let clientIdMissingError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: "Не найден client id. Выполнить запрос невозможно"]
            
            return NSError(
                domain: domain,
                code: 3002,
                userInfo: errorUserInfo
            )
        }()
        
        static let alreadyLoggedInError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: "Пользователь уже авторизован"]
            
            return NSError(
                domain: domain,
                code: 3003,
                userInfo: errorUserInfo
            )
        }()
        
        static let houseIdMissingError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: "Не найден house id. Выполнить запрос невозможно"]
            
            return NSError(
                domain: domain,
                code: 3004,
                userInfo: errorUserInfo
            )
        }()
        
        static func doorBlockedError(reason: String) -> NSError {
            let errorUserInfo = [NSLocalizedDescriptionKey: reason]
            
            return NSError(
                domain: domain,
                code: 3005,
                userInfo: errorUserInfo
            )
        }
        
        static let userPhoneMissing: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: "Не найден номер телефона текущего пользователя"]
            
            return NSError(
                domain: domain,
                code: 3006,
                userInfo: errorUserInfo
            )
        }()
        
        static func qrRegistrationFailed(reason: String) -> NSError {
            let errorUserInfo = [NSLocalizedDescriptionKey: reason]
            
            return NSError(
                domain: domain,
                code: 3007,
                userInfo: errorUserInfo
            )
        }
        
        static let contractNumberMissingError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: "Не найден номер договора. Выполнить запрос невозможно"]
            
            return NSError(
                domain: domain,
                code: 3008,
                userInfo: errorUserInfo
            )
        }()
    
    }
    
}

// MARK: AccessService Errors

extension NSError {
    
    enum AccessServiceError {
        
        private static let domain = "AccessServiceError"
        
        static let stateExtractionError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: "Невозможно восстановить состояние приложения"]
            
            return NSError(
                domain: domain,
                code: 4001,
                userInfo: errorUserInfo
            )
        }()
        
    }
    
}

// MARK: PushNotificationsService Errors

extension NSError {
    
    enum PushNotificationServiceError {
        
        private static let domain = "PushNotificationServiceError"
        
        /// Push-уведомления выключены для приложения на системном уровне
        static let pushDisabledInSystem = NSError(
            domain: domain,
            code: 5001,
            userInfo: [NSLocalizedDescriptionKey: "Push-уведомления выключены для приложения на системном уровне"]
        )
        
        /// Push-уведомления выключены в настройках приложения
        static let pushDisabledInApp = NSError(
            domain: domain,
            code: 5002,
            userInfo: [NSLocalizedDescriptionKey: "Push-уведомления выключены в настройках приложения"]
        )
        
        /// Отсутствует FCM токен
        static let fcmTokenMissing = NSError(
            domain: domain,
            code: 5003,
            userInfo: [NSLocalizedDescriptionKey: "Отсутствует FCM токен"]
        )
        
        static let instanceIdNotInitialized = NSError(
            domain: domain,
            code: 5004,
            userInfo: [NSLocalizedDescriptionKey: "InstanceID не инициализирован"]
        )
        
        static let connectionRequired = NSError(
            domain: domain,
            code: 5005,
            userInfo: [NSLocalizedDescriptionKey: "Для смены пользователя требуется интернет-соединение"]
        )
        
    }
    
}

// MARK: Permission Errors

extension NSError {
    
    enum PermissionError {
        
        private static let domain = "PermissionError"
        
        /// Доступ к контактам отсутствует
        static let noContactsPermission = NSError(
            domain: domain,
            code: 6001,
            userInfo: [NSLocalizedDescriptionKey: "Доступ к контактам отсутствует"]
        )
        
        /// Доступ к камере отсутствует
        static let noCameraPermission = NSError(
            domain: domain,
            code: 6002,
            userInfo: [NSLocalizedDescriptionKey: "Доступ к камере отсутствует"]
        )
        
        static let noMicPermission = NSError(
            domain: domain,
            code: 6003,
            userInfo: [NSLocalizedDescriptionKey: "Доступ к микрофону отсутствует"]
        )
        
    }
    
}
