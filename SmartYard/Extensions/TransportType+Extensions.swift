//
//  TransportType+Extensions.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import linphonesw

extension TransportType {
    
    init?(rawString: String) {
        switch rawString {
        case "udp": self = .Udp
        case "tcp": self = .Tcp
        case "tls": self = .Tls
        default: return nil
        }
    }
    
}
