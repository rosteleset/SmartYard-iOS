//
//  AccessShortcutType.swift
//  SmartYard
//
//  Created by Александр Попов on 12.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit

enum GateAccessShortcutType {
    
    case allCars
    case allPersons
    
    case addCar
    case addPerson
    
    var title: String {
        switch self {
        case .allCars: return L10n.Settings.AddressAccess.Shortcuts.allCars
        case .allPersons: return L10n.Settings.AddressAccess.Shortcuts.allPeople
        case .addCar: return L10n.Settings.AddressAccess.Shortcuts.addCar
        case .addPerson: return  L10n.Settings.AddressAccess.Shortcuts.addPerson
        }
    }
    
}
