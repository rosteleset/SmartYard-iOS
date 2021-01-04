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
    /*
    static func udp() -> SipConfig {
        return SipConfig(domain: "dm.lanta.me:54673", username: "1001", password: "ieNg8oof", transport: .Udp)
    }
    
    static func tcp() -> SipConfig {
        return SipConfig(domain: "dm.lanta.me:54675", username: "1003", password: "ieNg8oof", transport: .Tcp)
    }
    
    static func tls() -> SipConfig {
        return SipConfig(domain: "dm.lanta.me:54674", username: "1002", password: "ieNg8oof", transport: .Tls)
    }
    */
}
