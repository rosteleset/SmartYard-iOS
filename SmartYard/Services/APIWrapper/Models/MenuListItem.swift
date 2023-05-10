//
//  MenuListItem.swift
//  SmartYard
//
//  Created by Александр Васильев on 16.03.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import Foundation
import UIKit

enum MenuListItem {
    case essential(label: String, iconName: String, route: MainMenuRoute, order: Int)
    case optional(label: String, icon: UIImage?, extId: String, order: Int)
    
    var label: String {
        switch self {
            
        case .essential(label: let label, iconName: _, route: _, order: _):
            return label
        case .optional(label: let label, icon: _, extId: _, order: _):
            return label
        }
    }
    
    var order: Int {
        switch self {
        case .essential(label: _, iconName: _, route: _, order: let order):
            return order
        case .optional(label: _, icon: _, extId: _, order: let order):
            return order
        }
    }
    
    var iconName: String? {
        switch self {
        case .essential(label: _, iconName: let iconName, route: _, order: _):
            return iconName
        case .optional:
            return nil
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .essential:
            return nil
        case .optional(label: _, icon: let icon, extId: _, order: _):
            return icon
        }
    }
}
