//
//  SmartYardCheckBoxState.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

enum SmartYardCheckBoxState {
    
    case checkedInactive
    case uncheckedInactive
    case uncheckedActive
    case checkedActive
    
    var sortOrder: Int {
        switch self {
        case .checkedInactive:
            return 0
        case .uncheckedInactive:
            return 1
        case .uncheckedActive:
            return 2
        case .checkedActive:
            return 3
        }
    }
    
    var titleTextColor: UIColor? {
        switch self {
        case .checkedActive, .uncheckedActive: return UIColor.SmartYard.semiBlack
        case .checkedInactive, .uncheckedInactive: return UIColor.SmartYard.gray
        }
    }
    
    var descriptionTextColor: UIColor? {
        switch self {
        case .checkedActive, .uncheckedActive: return UIColor.SmartYard.semiBlack
        case .checkedInactive, .uncheckedInactive: return UIColor.SmartYard.gray.withAlphaComponent(0.5)
        }
    }
    
    var borderTintColor: UIColor? {
        switch self {
        case .checkedActive, .uncheckedActive: return UIColor.SmartYard.blue
        case .checkedInactive, .uncheckedInactive: return UIColor.SmartYard.gray.withAlphaComponent(0.5)
        }
    }
    
    var checkTintColor: UIColor? {
        switch self {
        case .checkedActive: return UIColor.SmartYard.blue
        case .uncheckedActive, .uncheckedInactive: return .clear
        case .checkedInactive: return UIColor.SmartYard.gray
        }
    }
    
}
