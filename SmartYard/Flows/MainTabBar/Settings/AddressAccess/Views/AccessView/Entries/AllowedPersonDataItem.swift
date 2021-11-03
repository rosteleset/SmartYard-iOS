//
//  AllowedPersonDataItem.swift
//  SmartYard
//
//  Created by admin on 19/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxDataSources

enum AllowedPersonDataItem: IdentifiableType, Equatable {
    
    case addContact
    case contact(person: AllowedPerson)
    
}

extension AllowedPersonDataItem {
    
    var identity: AllowedPersonDataItemIdentity {
        switch self {
        case .addContact: return .addContact
        case let .contact(person): return .contact(person: person)
        }
    }
    
}
