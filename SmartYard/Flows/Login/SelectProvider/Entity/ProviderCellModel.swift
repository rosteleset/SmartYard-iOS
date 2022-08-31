//
//  ProviderCellModel.swift
//  SmartYard
//
//  Created by LanTa on 13.06.2022.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct ProviderCellModel {
    
    let provider: APIProvider
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
