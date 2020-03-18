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
    let flatOwner: Bool?
    let contractOwner: Bool?
    let hasGates: Bool?
    let houseId: String?
    let flatId: String?
    let address: String
    let services: [String]
    let lcab: String?
    let roommates: [APIRoommate]
    
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
    
    private enum CodingKeys: String, CodingKey {
        case clientId, clientName, contractName, flatOwner, contractOwner, hasGates, houseId, flatId, address
        case services, lcab, roommates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        clientId = try? container.decode(String.self, forKey: .clientId)
        clientName = try? container.decode(String.self, forKey: .clientName)
        contractName = try? container.decode(String.self, forKey: .contractName)
        
        let flatOwnerRawValue = try? container.decode(String.self, forKey: .flatOwner)
        
        switch flatOwnerRawValue {
        case "t": flatOwner = true
        case "f": flatOwner = false
        default: flatOwner = nil
        }
        
        let contractOwnerRawValue = try? container.decode(String.self, forKey: .contractOwner)
        
        switch contractOwnerRawValue {
        case "t": contractOwner = true
        case "f": contractOwner = false
        default: contractOwner = nil
        }
        
        let hasGatesRawValue = try? container.decode(String.self, forKey: .hasGates)
        
        switch hasGatesRawValue {
        case "t": hasGates = true
        case "f": hasGates = false
        default: hasGates = nil
        }
        
        houseId = try? container.decode(String.self, forKey: .houseId)
        flatId = try? container.decode(String.self, forKey: .flatId)
        address = try container.decode(String.self, forKey: .address)
        services = try container.decode([String].self, forKey: .services)
        lcab = try? container.decode(String.self, forKey: .lcab)
        
        roommates = (try? container.decode([APIRoommate].self, forKey: .roommates)) ?? []
    }
    
}
