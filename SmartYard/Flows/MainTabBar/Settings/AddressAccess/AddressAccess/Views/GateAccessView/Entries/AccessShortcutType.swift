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
    
    // TODO: - add localize
    var title: String {
        switch self {
        case .allCars: return "Все автомобили"
        case .allPersons: return "Все люди"
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
