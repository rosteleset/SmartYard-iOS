//
//  ServicesModel.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct ServiceModel {
    
    let id: String
    let icon: String
    let name: String
    let description: String
    var state: SmartYardCheckBoxState
    
    mutating func toggleState() {
        guard state != .checkedInactive else {
            return
        }
        
        state = state == .uncheckedActive ? .checkedActive : .uncheckedActive
    }
    
}
