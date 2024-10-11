//
//  CheckBoxState.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 02.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation
import UIKit

enum CheckBoxState {
    
    case checked
    case unchecked
    
    var sortOrder: Int {
        switch self {
        case .unchecked:
            return 0
        case .checked:
            return 1
        }
    }
    
    var titleTextColor: UIColor? {
        switch self {
        case .checked:   return UIColor.SmartYard.textAddon
        case .unchecked: return UIColor.SmartYard.textAddon
        }
    }
    
    var descriptionTextColor: UIColor? {
        switch self {
        case .checked:   return UIColor.SmartYard.textAddon.withAlphaComponent(0.6)
        case .unchecked: return UIColor.SmartYard.textAddon.withAlphaComponent(0.6)
        }
    }
    
    var iconImage: UIImage? {
        switch self {
        case .checked:   return UIImage(named: "CheckSelected")
        case .unchecked: return UIImage(named: "CheckUnselected")
        }
    }
}
