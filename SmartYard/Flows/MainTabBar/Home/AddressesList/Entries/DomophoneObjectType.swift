//
//  DomophoneObjectType.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

enum DomophoneObjectType: String, Decodable {
    
    case entrance
    case wicket
    case gate
    case barrier
    
    var icon: UIImage? {
        switch self {
        case .entrance: return UIImage(named: "HouseIcon")
        case .wicket: return nil
        case .gate: return UIImage(named: "GateIcon")
        case .barrier: return UIImage(named: "BarrierIcon")
        }
    }
    
}
