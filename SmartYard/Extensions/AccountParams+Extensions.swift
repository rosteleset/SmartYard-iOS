//
//  AccountParams+Extensions.swift
//  SmartYard
//
//  Created by Александр Васильев on 18.10.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import linphonesw

extension AccountParams {
    func setAccountConfiguration(core: Core, configuration config: SipConfig) {
        guard let identityAddress = core.interpretUrl(url: "sip:\(config.username)@\(config.domain)"),
              let proxyAddress = core.interpretUrl(url: "<sip:\(config.domain);transport=\(config.transport)>")
        else {
            return
        }
        do {
            try identityAddress.setTransport(newValue: config.transport)
            try setIdentityaddress(newValue: identityAddress)
            try setServeraddress(newValue: proxyAddress)
            registerEnabled = true
            guard let account = try? core.createAccount(params: self) else {
                return
            }
            try core.addAccount(account: account)
            core.defaultAccount = account
        } catch {
            print("Error: \(error)")
        }
        
    }
}
