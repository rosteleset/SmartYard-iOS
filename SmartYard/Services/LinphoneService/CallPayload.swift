//
//  CallPayload.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import linphonesw

struct CallPayload {
    
    let uuid = UUID()
    
    let username: String
    let password: String
    let server: String
    let port: String
    let transport: TransportType
    let image: String
    let liveImage: String
    let dtmf: String
    let callerId: String
    
    var asPushNotificationPayload: [AnyHashable: Any] {
        return [
            "extension": username,
            "pass": password,
            "server": server,
            "port": port,
            "transport": transport.rawString,
            "live": liveImage,
            "image": image,
            "dtmf": dtmf,
            "callerId": callerId
        ]
    }
    
    var sipConfig: SipConfig {
        return SipConfig(
            domain: "\(server):\(port)",
            username: username,
            password: password,
            transport: transport
        )
    }
    
    init?(pushNotificationPayload data: [AnyHashable: Any]) {
        guard let username = data["extension"] as? String,
            let password = data["pass"] as? String,
            let server = data["server"] as? String,
            let port = data["port"] as? String,
            let rawTransport = data["transport"] as? String,
            let transport = TransportType(rawString: rawTransport),
            let liveImage = data["live"] as? String,
            let image = data["image"] as? String,
            let dtmf = data["dtmf"] as? String,
            let callerId = data["callerId"] as? String else {
            return nil
        }
        
        self.username = username
        self.password = password
        self.server = server
        self.port = port
        self.transport = transport
        self.liveImage = liveImage
        self.image = image
        self.dtmf = dtmf
        self.callerId = callerId
    }
    
}
