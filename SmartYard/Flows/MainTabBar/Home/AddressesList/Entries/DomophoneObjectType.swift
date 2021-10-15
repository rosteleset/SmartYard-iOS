//
//  DomophoneObjectType.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

enum DomophoneObjectType: String, Decodable {
    
    case entrance
    case wicket
    case gate
    case barrier
    
    var icon: UIImage? {
        return UIImage(named: iconImageName)
    }
    
    var iconImageName: String {
        switch self {
        case .entrance: return "HouseIcon"
        case .wicket: return "WicketIcon"
        case .gate: return "GateIcon"
        case .barrier: return "BarrierIcon"
        }
    }
    
}
