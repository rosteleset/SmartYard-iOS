//
//  CallPayload.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import linphonesw

struct CallPayload {
    
    let username: String
    let password: String
    let server: String
    let port: String
    let transport: TransportType
    let image: String
    let liveImage: String
    
    let domophoneId: String?
    let flatId: String?
    
    var asPushNotificationPayload: [AnyHashable: Any] {
        var mainPayload: [AnyHashable: Any] = [
            "extension": username,
            "pass": password,
            "server": server,
            "port": port,
            "transport": transport.rawString,
            "live": liveImage,
            "image": image
        ]
        
        if let domophoneId = domophoneId {
            mainPayload["domophoneId"] = domophoneId
        }
        
        if let flatId = flatId {
            mainPayload["flatId"] = flatId
        }
        
        return mainPayload
    }
    
    var domophoneString: String? {
        guard let domophoneId = domophoneId else {
            return nil
        }
        
        return "ID домофона: \(domophoneId)"
    }
    
    var flatString: String? {
        guard let flatId = flatId else {
            return nil
        }
        
        return "ID квартиры: \(flatId)"
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
            let image = data["image"] as? String else {
            return nil
        }
        
        self.username = username
        self.password = password
        self.server = server
        self.port = port
        self.transport = transport
        self.liveImage = liveImage
        self.image = image
        
        self.domophoneId = data["domophoneId"] as? String
        self.flatId = data["flatId"] as? String
    }
    
}
