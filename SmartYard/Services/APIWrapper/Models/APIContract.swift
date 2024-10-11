//
//  APIContract.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 31.05.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct APIContract: Decodable {

    let houseId: String
    let address: String
    let cityId: Int
    let city: String
    let clientId: Int
    let contractName: String
    let hasPlog: Bool
    let isBlocked: Bool
    let services: [String]
    let balance: Double
    let bonus: Double
    let isOwner: Bool
    let hasGates: Bool
    let limitStatus: Bool
    let limitAvailable: Bool
    let limitDays: Int?
    let isParentControl: Bool
    let parentControlStatus: Bool?

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

    private enum CodingKeys: String, CodingKey {
        case houseId
        case address
        case cityId
        case city = "cityTitle"
        case clientId
        case contractName
        case hasPlog
        case isBlocked = "blocked"
        case services
        case balance
        case bonus
        case isOwner = "contractOwner"
        case hasGates
        case limitStatus
        case limitAvailable
        case limitDays
        case parentControlEnable
        case parentControlStatus
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        houseId = try container.decode(String.self, forKey: .houseId)
        address = try container.decode(String.self, forKey: .address)
        
        cityId = try container.decode(Int.self, forKey: .cityId)
        city = try container.decode(String.self, forKey: .city)

        clientId = try container.decode(Int.self, forKey: .clientId)
        contractName = try container.decode(String.self, forKey: .contractName)
        
        let hasPlogRawValue = (try? container.decode(String.self, forKey: .hasPlog)) ?? ""
        switch hasPlogRawValue {
        case "t": hasPlog = true
        default: hasPlog = false
        }

        let isBlockedRawValue = (try? container.decode(String.self, forKey: .isBlocked)) ?? ""
        
        switch isBlockedRawValue {
        case "t": isBlocked = true
        default: isBlocked = false
        }
        
        services = try container.decode([String].self, forKey: .services)
        balance = try container.decode(Double.self, forKey: .balance)
        bonus = try container.decode(Double.self, forKey: .bonus)
        
        let isOwnerRawValue = (try? container.decode(String.self, forKey: .isOwner)) ?? ""
        
        switch isOwnerRawValue {
        case "t": isOwner = true
        default: isOwner = false
        }
        
        let hasGatesRawValue = (try? container.decode(String.self, forKey: .hasGates)) ?? ""
        
        switch hasGatesRawValue {
        case "t": hasGates = true
        default: hasGates = false
        }
        
        limitStatus = try container.decode(Bool.self, forKey: .limitStatus)
        limitAvailable = try container.decode(Bool.self, forKey: .limitAvailable)
        limitDays = try? container.decode(Int.self, forKey: .limitDays)

        let isParentControlRawValue = (try? container.decode(String.self, forKey: .parentControlEnable)) ?? ""
        
        switch isParentControlRawValue {
        case "t": isParentControl = true
        default: isParentControl = false
        }

        let parentControlStatusRawValue = (try? container.decode(String.self, forKey: .parentControlStatus)) ?? ""
        
        switch parentControlStatusRawValue {
        case "t": parentControlStatus = true
        case "f": parentControlStatus = false
        default: parentControlStatus = nil
        }
//        print(contractName, services, isParentControlRawValue, parentControlStatus)
    }
}
