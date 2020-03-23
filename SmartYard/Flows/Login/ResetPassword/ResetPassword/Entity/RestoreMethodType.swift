//
//  ResetMethodType.swift
//  SmartYard
//
//  Created by Mad Brains on 18.03.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

enum RestoreMethodType {
    
    case byEmail(type: String, contactId: String, contact: String)
    case byPhoneNumber(type: String, contactId: String, contact: String)

    init?(rawValue: String?, contactId: String, contact: String) {
        guard let rawValue = rawValue else {
            return nil
        }
        
        switch rawValue {
        case "email": self = .byEmail(type: rawValue, contactId: contactId, contact: contact)
        case "phone": self = .byPhoneNumber(type: rawValue, contactId: contactId, contact: contact)
        default: return nil
        }
    }
    
    var displayedText: String {
        let baseText = "Выслать код восстановления на "
        switch self {
        case let .byEmail(_, _, contact): return baseText + "почту \(contact)"
        case let .byPhoneNumber(_, _, contact): return baseText + "телефон \(contact)"
        }
    }
    
    var contactId: String {
        switch self {
        case .byEmail(_, let contactId, _):
            return contactId
        case .byPhoneNumber(_, let contactId, _):
            return contactId
        }
    }
    
    var contact: String {
        switch self {
        case .byEmail(_, _, let contact):
            return contact
        case .byPhoneNumber(_, _, let contact):
            return contact
        }
    }
    
}

