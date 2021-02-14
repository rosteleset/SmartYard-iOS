//
//  SipConfig.swift
//  SmartYard
//
//  Created by admin on 28/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import linphonesw

struct SipConfig {
    
    let domain: String
    let username: String
    let password: String
    let transport: TransportType
    let stun: String?
}
