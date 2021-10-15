//
//  SberbankPayError.swift
//  SmartYard
//
//  Created by Mad Brains on 27.05.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct SberbankPayError: Codable {
    
    let code: String
    let description: String
    let message: String
    
}
