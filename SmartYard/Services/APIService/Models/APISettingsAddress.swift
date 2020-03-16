//
//  APISettingsAddress.swift
//  SmartYard
//
//  Created by Mad Brains on 25.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct APISettingsAddress: Decodable {
    
    let clientId: String?
    let clientName: String?
    let contractName: String?
    let houseId: String?
    let flatId: String?
    let address: String
    let services: [String]
    let roommates: [APIRoommate]?
    
    var servicesAvailability: [SettingsServiceType: Bool] {
        return [
            .internet: services.contains("internet"),
            .iptv: services.contains("iptv"),
            .ctv: services.contains("ctv"),
            .phone: services.contains("phone"),
            .cctv: services.contains("cctv"),
            .domophone: services.contains("domophone"),
            .gsm: services.contains("gsm")
        ]
    }
    
    var uniqueId: String {
        return (clientId ?? "") + (flatId ?? "")
    }
    
}
