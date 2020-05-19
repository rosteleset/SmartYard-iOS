//
//  SberbankPayProcessResponseData.swift
//  SmartYard
//
//  Created by Mad Brains on 14.05.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct SberbankPayProcessResponseData: Codable {
    
    let success: Bool
    let data: SberbankPayData?
    
}
