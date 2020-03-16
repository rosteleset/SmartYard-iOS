//
//  ServicesModel.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct ServiceModel {
    
    let id: String
    let icon: String
    let name: String
    let description: String
    var state: ServiceState
    
    mutating func toogleState() {
        guard state != .checkedInactive else {
            return
        }
        
        state = state == .uncheckedActive ? .checkedActive : .uncheckedActive
    }
    
}
