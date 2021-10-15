//
//  AccountCreator+Extensions.swift
//  SmartYard
//
//  Created by admin on 31/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import linphonesw

extension AccountCreator {
    
    func setAccountConfiguration(_ configuration: SipConfig) {
        domain = configuration.domain
        transport = configuration.transport
        username = configuration.username
        password = configuration.password
    }
    
}
