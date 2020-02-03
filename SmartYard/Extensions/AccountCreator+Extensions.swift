//
//  AccountCreator+Extensions.swift
//  SmartYard
//
//  Created by admin on 31/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
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
