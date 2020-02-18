//
//  NSError+Extensions.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

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
        
    }
    
}

extension NSError {
    
    enum APIServiceError {
        
        private static let domain = "APIServiceError"
        
        static let unknownError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: "Неизвестная ошибка"]
            
            return NSError(
                domain: domain,
                code: 2001,
                userInfo: errorUserInfo
            )
        }()
        
        static let mappingError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: "Ошибка маппинга данных"]
            
            return NSError(
                domain: domain,
                code: 2002,
                userInfo: errorUserInfo
            )
        }()
        
        static let emptyDataError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: "Ошибка маппинга поля Data, либо же оно отсутствует"]

            return NSError(
                domain: domain,
                code: 2003,
                userInfo: errorUserInfo
            )
        }()
        
    }
    
}

extension NSError {
    
    enum APIWrapperError {
        
        private static let domain = "APIWrapperError"
        
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
        
    }
    
}

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
