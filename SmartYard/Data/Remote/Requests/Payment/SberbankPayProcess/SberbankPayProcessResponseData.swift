//
//  SberbankPayProcessResponseData.swift
//  SmartYard
//
//  Created by Mad Brains on 14.05.2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import Foundation

struct SberbankPayProcessResponseData: Codable {
    
    let success: Bool
    let data: SberbankPayData?
    let error: SberbankPayError?
    
}
