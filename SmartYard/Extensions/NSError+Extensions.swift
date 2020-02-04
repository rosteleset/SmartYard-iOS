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
