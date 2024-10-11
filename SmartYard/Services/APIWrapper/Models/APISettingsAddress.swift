//
//  APISettingsAddress.swift
//  SmartYard
//
//  Created by Mad Brains on 25.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable cyclomatic_complexity line_length

struct APISettingsAddress: Decodable {
    
    let clientId: String?
    let clientName: String?
    let contractName: String?
    let flatOwner: Bool?
    let contractOwner: Bool?
    let hasGates: Bool?
    let hasPlog: Bool
    let houseId: String?
    let flatId: String?
    let flatNumber: String?
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
            .gsm: services.contains("gsm"),
            .barrier: services.contains("barrier")
        ]
    }
    
    var uniqueId: String {
        return (clientId ?? "") + (flatId ?? "")
    }
    
    private enum CodingKeys: String, CodingKey {
        case clientId, clientName, contractName, flatOwner, contractOwner, hasGates, houseId, flatId, flatNumber, address
        case services, lcab, roommates, hasPlog
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
        
        let hasPlogRawValue = try? container.decode(String.self, forKey: .hasPlog)
        switch hasPlogRawValue {
        case "t": hasPlog = true
        default: hasPlog = false
        }
        
        let hid = try container.decode(Int.self, forKey: .houseId)
        houseId = String(hid)
        
        flatId = try? container.decode(String.self, forKey: .flatId)
        flatNumber = try? container.decode(String.self, forKey: .flatNumber)
        
        address = try container.decode(String.self, forKey: .address)
        services = try container.decode([String].self, forKey: .services)
        lcab = try? container.decode(String.self, forKey: .lcab)
        
        roommates = (try? container.decode([APIRoommate].self, forKey: .roommates)) ?? []
        
    }
    
}
// swiftlint:enable cyclomatic_complexity line_length
