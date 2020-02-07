//
//  DomophoneObjectType.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

enum DomophoneObjectType {
    
    case barrier
    case gate
    case house
    
    var icon: UIImage? {
        switch self {
        case .barrier: return UIImage(named: "BarrierIcon")
        case .gate: return UIImage(named: "GateIcon")
        case .house: return UIImage(named: "HouseIcon")
        }
    }
    
}
