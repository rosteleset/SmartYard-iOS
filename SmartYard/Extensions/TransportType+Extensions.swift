//
//  TransportType+Extensions.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import linphonesw

extension TransportType {
    
    var rawString: String {
        switch self {
        case .Udp: return "udp"
        case .Tcp: return "tcp"
        case .Tls: return "tls"
        case .Dtls: return "dtls"
        }
    }
    
    init?(rawString: String) {
        switch rawString {
        case "udp": self = .Udp
        case "tcp": self = .Tcp
        case "tls": self = .Tls
        case "dtls": self = .Dtls
        default: return nil
        }
    }
    
}
