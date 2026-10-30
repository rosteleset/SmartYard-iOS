//
//  GateAccessDataItem.swift
//  SmartYard
//
//  Created by Александр Попов on 11.06.2025.
//  Copyright © 2025 Sesameware. All rights reserved.
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
        case .car(let car): return .plateNumber(car.identity)
        case .person(let person): return .phoneNumber(person.apiNumber)
        case .shortcut: return .shortcut
        }
    }
    
    static func == (lhs: GateAccessDataItem, rhs: GateAccessDataItem) -> Bool {
        switch (lhs, rhs) {
        case let (.car(left), .car(right)): return left == right
        default: return lhs.identity == rhs.identity
        }
    }
    
}
