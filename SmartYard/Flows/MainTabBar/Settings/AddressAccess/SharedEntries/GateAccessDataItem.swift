//
//  GateAccessDataItem.swift
//  SmartYard
//
//  Created by Александр Попов on 11.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxDataSources

enum GateAccessDataItem: IdentifiableType, Equatable {
    
    case car(AllowedCar)
    case person(AllowedPerson)
    case shortcut(GateAccessShortcutType)
    
}

extension GateAccessDataItem {
    
    var identity: GateAccessDataItemIdentity {
        switch self {
        case .car(let car): return .plateNumber(car.apiNumber)
        case .person(let person): return .phoneNumber(person.apiNumber)
        case .shortcut: return .shortcut
        }
    }
    
    static func == (lhs: GateAccessDataItem, rhs: GateAccessDataItem) -> Bool {
        lhs.identity == rhs.identity
    }
    
}
