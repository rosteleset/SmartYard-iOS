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
            let errorUserInfo = [NSLocalizedDescriptionKey: L10n.Error.Internal.selfDestroyed]
            
            return NSError(
                domain: domain,
                code: 1001,
                userInfo: errorUserInfo
            )
        }()
        
        static let unknownError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: L10n.Error.Common.unknown]
            
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
            userInfo: [NSLocalizedDescriptionKey: L10n.Error.Camera.setupFailed]
        )
    }
    
}

// MARK: APIWrapper Errors

extension NSError {
    
    enum APIWrapperError {
        
        static let domain = "APIWrapperError"
        
        static let baseResponseMappingError: NSError = {
            let description = L10n.Error.Network.baseModelParsingFailed
            
            return NSError(
                domain: domain,
                code: 3100,
                userInfo: [NSLocalizedDescriptionKey: description]
            )
        }()
        
        static let noDataError: NSError = {
            let description = L10n.Error.Network.dataFieldMappingFailed

            return NSError(
                domain: domain,
                code: 3101,
                userInfo: [NSLocalizedDescriptionKey: description]
            )
        }()
        
        static let noConnectionError = NSError(
            domain: domain,
            code: 3102,
            userInfo: [NSLocalizedDescriptionKey: L10n.Error.Network.noConnection]
        )
        
        static func codeIsNotSuccessful(_ code: Int) -> NSError {
            return NSError(
                domain: domain,
                code: code,
                userInfo: [
                    NSLocalizedDescriptionKey: String.localizedStringWithFormat(
                        L10n.Error.Request.executionFailed,
                        String(code)
                    )
                ]
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
            let errorUserInfo = [NSLocalizedDescriptionKey: L10n.Error.Auth.accessTokenMissing]
            
            return NSError(
                domain: domain,
                code: 3001,
                userInfo: errorUserInfo
            )
        }()
        
        static let clientIdMissingError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: L10n.Error.Auth.clientIdMissing]
            
            return NSError(
                domain: domain,
                code: 3002,
                userInfo: errorUserInfo
            )
        }()
        
        static let alreadyLoggedInError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: L10n.Error.Auth.userAlreadyLoggedIn]
            
            return NSError(
                domain: domain,
                code: 3003,
                userInfo: errorUserInfo
            )
        }()
        
        static let houseIdMissingError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: L10n.Error.Address.houseIdMissing]
            
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
            let errorUserInfo = [NSLocalizedDescriptionKey: L10n.Error.Auth.currentUserPhoneMissing]
            
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
            let errorUserInfo = [NSLocalizedDescriptionKey: L10n.Error.Auth.contractNumberNotFound]
            
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
            let errorUserInfo = [NSLocalizedDescriptionKey: L10n.Error.App.restoreStateFailed]
            
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
            userInfo: [NSLocalizedDescriptionKey: L10n.Error.Notifications.systemDisabled]
        )
        
        /// Push-уведомления выключены в настройках приложения
        static let pushDisabledInApp = NSError(
            domain: domain,
            code: 5002,
            userInfo: [NSLocalizedDescriptionKey: L10n.Error.Notifications.appDisabled]
        )
        
        /// Отсутствует FCM токен
        static let fcmTokenMissing = NSError(
            domain: domain,
            code: 5003,
            userInfo: [NSLocalizedDescriptionKey: L10n.Error.Notifications.fcmTokenMissing]
        )
        
        static let instanceIdNotInitialized = NSError(
            domain: domain,
            code: 5004,
            userInfo: [NSLocalizedDescriptionKey: L10n.Error.Notifications.instanceIdMissing]
        )
        
        static let connectionRequired = NSError(
            domain: domain,
            code: 5005,
            userInfo: [NSLocalizedDescriptionKey: L10n.Error.Network.internetRequiredToChangeUser]
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
            userInfo: [NSLocalizedDescriptionKey: L10n.Error.Permissions.contactsDenied]
        )
        
        /// Доступ к камере отсутствует
        static let noCameraPermission = NSError(
            domain: domain,
            code: 6002,
            userInfo: [NSLocalizedDescriptionKey: L10n.Error.Permissions.cameraDenied]
        )
        
        static let noMicPermission = NSError(
            domain: domain,
            code: 6003,
            userInfo: [NSLocalizedDescriptionKey: L10n.Permissions.Microphone.title]
        )
        
    }
    
}
