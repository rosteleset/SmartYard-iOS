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
            let errorUserInfo = [NSLocalizedDescriptionKey: NSLocalizedString("self destroyed", comment: "")]
            
            return NSError(
                domain: domain,
                code: 1001,
                userInfo: errorUserInfo
            )
        }()
        
        static let unknownError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: NSLocalizedString("Unknown error", comment: "")]
            
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
            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Failed to setup camera", comment: "")]
        )
    }
    
}

// MARK: APIWrapper Errors

extension NSError {
    
    enum APIWrapperError {
        
        static let domain = "APIWrapperError"
        
        static let baseResponseMappingError: NSError = {
            let description = NSLocalizedString("Failed to represent server response as base model", comment: "")
            
            return NSError(
                domain: domain,
                code: 3100,
                userInfo: [NSLocalizedDescriptionKey: description]
            )
        }()
        
        static let noDataError: NSError = {
            let description = NSLocalizedString("Error mapping the Data field, or it is missing with a code other than 204", comment: "")

            return NSError(
                domain: domain,
                code: 3101,
                userInfo: [NSLocalizedDescriptionKey: description]
            )
        }()
        
        static let noConnectionError = NSError(
            domain: domain,
            code: 3102,
            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("noConnectionError", comment: "")]
        )
        
        static func codeIsNotSuccessful(_ code: Int) -> NSError {
            return NSError(
                domain: domain,
                code: code,
                userInfo: [
                    NSLocalizedDescriptionKey: String.localizedStringWithFormat(
                        NSLocalizedString("An error occurred while executing the request", comment: ""),
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
            let errorUserInfo = [NSLocalizedDescriptionKey:
                NSLocalizedString("Access token not found. Request cannot be completed", comment: "")
            ]
            
            return NSError(
                domain: domain,
                code: 3001,
                userInfo: errorUserInfo
            )
        }()
        
        static let clientIdMissingError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey:
                NSLocalizedString("Client id not found. Request cannot be completed", comment: "")
            ]
            
            return NSError(
                domain: domain,
                code: 3002,
                userInfo: errorUserInfo
            )
        }()
        
        static let alreadyLoggedInError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey: NSLocalizedString("User is already logged in", comment: "")]
            
            return NSError(
                domain: domain,
                code: 3003,
                userInfo: errorUserInfo
            )
        }()
        
        static let houseIdMissingError: NSError = {
            let errorUserInfo = [NSLocalizedDescriptionKey:
                NSLocalizedString("House id not found. Request cannot be completed", comment: "")
            ]
            
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
            let errorUserInfo = [NSLocalizedDescriptionKey:
                NSLocalizedString("Current user's phone number not found", comment: "")
            ]
            
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
            let errorUserInfo = [NSLocalizedDescriptionKey:
                NSLocalizedString("The contract number was not found. It is impossible to complete the request", comment: "")
            ]
            
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
            let errorUserInfo = [NSLocalizedDescriptionKey: NSLocalizedString("Unable to restore application state", comment: "")]
            
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
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Push notifications are disabled for the application at the system level", comment: "")
            ]
        )
        
        /// Push-уведомления выключены в настройках приложения
        static let pushDisabledInApp = NSError(
            domain: domain,
            code: 5002,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Push notifications are disabled in the app settings", comment: "")
            ]
        )
        
        /// Отсутствует FCM токен
        static let fcmTokenMissing = NSError(
            domain: domain,
            code: 5003,
            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Missing FCM token", comment: "")]
        )
        
        static let instanceIdNotInitialized = NSError(
            domain: domain,
            code: 5004,
            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("InstanceID not initialized", comment: "")]
        )
        
        static let connectionRequired = NSError(
            domain: domain,
            code: 5005,
            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Internet connection required to change user", comment: "")]
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
            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("No access to contacts", comment: "")]
        )
        
        /// Доступ к камере отсутствует
        static let noCameraPermission = NSError(
            domain: domain,
            code: 6002,
            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("No camera access", comment: "")]
        )
        
        static let noMicPermission = NSError(
            domain: domain,
            code: 6003,
            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("No microphone access", comment: "")]
        )
        
    }
    
}
