//
//  AccessShortcutType.swift
//  SmartYard
//
//  Created by Александр Попов on 12.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit

enum AccessShortcutType {
    
    case allCars
    case allPersons
    
    var title: String {
        switch self {
        case .allCars: return L10n.Settings.AddressAccess.Shortcuts.allCars
        case .allPersons: return L10n.Settings.AddressAccess.Shortcuts.allPeople
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .allCars: return UIImage(named: "DefaultCarIcon")
        case .allPersons: return UIImage(named: "DefaultUserIcon")
        }
    }
    
    var identity: String {
        switch self {
        case .allCars: return "allCars"
        case .allPersons: return "allPersons"
        }
    }
    
}
