//
//  RestoreMethodCellModel.swift
//  SmartYard
//
//  Created by Mad Brains on 19.03.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct RestoreMethodCellModel {
    
    let method: RestoreMethod
    var state: SmartYardCheckBoxState
    
    mutating func toggleState() {
        guard state != .checkedInactive && state != .uncheckedInactive else {
            return
        }
        
        state = state == .uncheckedActive ? .checkedActive : .uncheckedActive
    }
    
    mutating func setUncheckedState() {
        state = .uncheckedActive
    }
    
}
