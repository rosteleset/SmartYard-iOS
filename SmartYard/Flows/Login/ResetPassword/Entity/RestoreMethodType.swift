//
//  ResetMethodType.swift
//  SmartYard
//
//  Created by Mad Brains on 18.03.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

enum ResetMethodType {
    
    case byEmail(mail: String)
    case byPhoneNumber(phoneNumber: String)

    init?(rawValue: String?) {
        guard let rawValue = rawValue else {
            return nil
        }
        
        switch rawValue {
        case "email": self = .byEmail(mail: rawValue)
        case "phone": self = .byPhoneNumber(phoneNumber: rawValue)
        default: return nil
        }
    }
    
    var displayedText: String {
        let baseText = "Выслать код восстановления "
        switch self {
        case let .byEmail(mail): return baseText + "на почту \(mail)"
        case let .byPhoneNumber(phoneNumber): return baseText + "на телефон \(phoneNumber)"
        }
    }
    
}

