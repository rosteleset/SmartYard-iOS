//
//  APIIntercomSettings.swift
//  SmartYard
//
//  Created by Mad Brains on 21.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct APIIntercomSettings: Codable {
    
    let enableDoorCode: String
    let cms: String
    let voip: String
    let autoOpen: String
    let whiteRabbit: String
    
}

