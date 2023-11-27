//
//  ResetMethodType.swift
//  SmartYard
//
//  Created by Mad Brains on 18.03.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

enum RestoreMethod {
    
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
        let baseText = NSLocalizedString("Confirmation code has been sent to your ", comment: "")
        switch self {
        case let .byEmail(_, contact): return baseText + NSLocalizedString("email", comment: "") + " \(contact)"
        case let .byPhoneNumber(_, contact): return baseText + NSLocalizedString("phone", comment: "") + " \(contact)"
        }
    }
    
    var displayedTextShouldSent: String {
        let baseText = NSLocalizedString("Send recovery code to ", comment: "")
        switch self {
        case let .byEmail(_, contact): return baseText + NSLocalizedString("email", comment: "") + " \(contact)"
        case let .byPhoneNumber(_, contact): return baseText + NSLocalizedString("phone", comment: "") + " \(contact)"
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
