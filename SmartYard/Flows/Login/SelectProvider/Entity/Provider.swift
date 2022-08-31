//
//  Provider.swift
//  SmartYard
//
//  Created by LanTa on 13.06.2022.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

enum Provider {
    
    case byEmail(contactId: String, contact: String)
    case byPhoneNumber(contactId: String, contact: String)

    init?(apiRestoreData: APIRestoreData) {
        guard let type = apiRestoreData.type,
            let contactId = apiRestoreData.id,
            let contact = apiRestoreData.contact else {
            return nil
        }
        
        switch type {
        case "email": self = .byEmail(contactId: contactId, contact: contact)
        case "phone": self = .byPhoneNumber(contactId: contactId, contact: contact)
        default: return nil
        }
    }
    
    var displayedTextHasBeenSent: String {
        let baseText = "Код подтверждения отправлен на "
        switch self {
        case let .byEmail(_, contact): return baseText + "почту \(contact)"
        case let .byPhoneNumber(_, contact): return baseText + "телефон \(contact)"
        }
    }
    
    var displayedTextShouldSent: String {
        let baseText = "Выслать код восстановления на "
        switch self {
        case let .byEmail(_, contact): return baseText + "почту \(contact)"
        case let .byPhoneNumber(_, contact): return baseText + "телефон \(contact)"
        }
    }
    
    var contactId: String {
        switch self {
        case let .byEmail(contactId, _), let .byPhoneNumber(contactId, _): return contactId
        }
    }
    
    var contact: String {
        switch self {
        case let .byEmail(_, contact), let .byPhoneNumber(_, contact): return contact
        }
    }
    
}
