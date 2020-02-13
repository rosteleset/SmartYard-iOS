//
//  ServiceStates.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit

enum ServiceState {
    
    case checkedActive
    case checkedInactive
    case uncheckedActive
    
    var titleTextColor: UIColor? {
        switch self {
        case .checkedActive, .uncheckedActive: return UIColor.SmartYard.semiBlack
        case .checkedInactive: return UIColor.SmartYard.gray
        }
    }
    
    var descriptionTextColor: UIColor? {
        switch self {
        case .checkedActive, .uncheckedActive: return UIColor.SmartYard.semiBlack
        case .checkedInactive: return UIColor.SmartYard.gray.withAlphaComponent(0.5)
        }
    }
    
    var borderTintColor: UIColor? {
        switch self {
        case .checkedActive, .uncheckedActive: return UIColor.SmartYard.blue
        case .checkedInactive: return UIColor.SmartYard.gray
        }
    }
    
    var checkTintColor: UIColor? {
        switch self {
        case .checkedActive: return UIColor.SmartYard.blue
        case .uncheckedActive: return .clear
        case .checkedInactive: return UIColor.SmartYard.gray
        }
    }
    
}
