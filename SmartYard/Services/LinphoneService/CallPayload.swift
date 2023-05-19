//
//  CallPayload.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
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
    let stun: String?
    let callerId: String
    let hash: String?
    let useCallKit: Bool
    
    var asPushNotificationPayload: [AnyHashable: Any] {
        var params = [
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
        
        if let stun = stun {
            params["stun"] = stun
        }
        
        return params
    }
    
    var sipConfig: SipConfig {
        SipConfig(
            domain: "\(server):\(port)",
            username: username,
            password: password,
            transport: transport,
            stun: stun,
            useCallKit: useCallKit
        )
    }
    
    var uniqueIdentifier: String {
        username + password + server + port
    }
    
    init?(pushNotificationPayload data: [AnyHashable: Any], useCallKit: Bool) {
        let accessService = AccessService()
        
        let hash = data["hash"] as? String ?? ""
        
        guard let username = data["extension"] as? String,
              let password = data["pass"] as? String != nil ? data["pass"] as? String : hash,
            let server = data["server"] as? String,
            let port = data["port"] as? String,
            let rawTransport = data["transport"] as? String,
            let transport = TransportType(rawString: rawTransport),
            let liveImage = data["live"] as? String != nil ? data["live"] as? String : "\(accessService.backendURL)/call/live/\(hash)",
            let image = data["image"] as? String != nil ? data["image"] as? String : "\(accessService.backendURL)/call/camshot/\(hash)",
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
        self.stun = data["stun"] as? String
        self.hash = data["hash"] as? String
        self.useCallKit = useCallKit
    }
    
}
