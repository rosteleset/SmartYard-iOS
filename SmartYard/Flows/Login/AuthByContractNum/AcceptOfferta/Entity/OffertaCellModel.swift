//
//  OffertaCellModel.swift
//  SmartYard
//
//  Created by devcentra on 19.02.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct OffertaCellModel {
    
    let id: String
    let name: String
    let url: URL?
    var state: Bool
    
    mutating func toggleState() {
        state = !state
    }
    
}
