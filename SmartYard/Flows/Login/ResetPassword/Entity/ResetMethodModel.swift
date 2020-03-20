//
//  ResetMethodModel.swift
//  SmartYard
//
//  Created by Mad Brains on 19.03.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct ResetMethodModel {
    
    let type: ResetMethodType
    var state: SmartYardCheckBoxState
    
    mutating func toogleState() {
        guard state != .checkedInactive else {
            return
        }
        
        state = state == .uncheckedActive ? .checkedActive : .uncheckedActive
    }
    
    mutating func setUncheckedState() {
        state = .uncheckedActive
    }
    
}
