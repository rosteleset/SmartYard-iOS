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
        case .allCars: return NSLocalizedString("All cars", comment: "")
        case .allPersons: return NSLocalizedString("All people", comment: "")
        case .addCar: return NSLocalizedString("Add car", comment: "")
        case .addPerson: return  NSLocalizedString("Add person", comment: "")
        }
    }
    
}
