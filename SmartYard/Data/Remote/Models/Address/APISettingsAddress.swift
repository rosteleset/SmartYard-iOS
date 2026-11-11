//
//  APISettingsAddress.swift
//  SmartYard
//
//  Created by Mad Brains on 25.02.2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

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
    let doorCode: String?
    let address: String
    let services: [String]
    let availableServices: [APIServiceModel]?
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

    var controlPanelServiceStates: [SettingsServiceType: Bool] {
        let supportedServices: Set<SettingsServiceType> = [.internet, .iptv, .phone, .domophone, .cctv]
        let visibleServices = availableServices.map { services in
            Set(services.compactMap { SettingsServiceType(rawValue: $0.icon) })
        }

        return servicesAvailability.filter { serviceType, _ in
            supportedServices.contains(serviceType) && (visibleServices?.contains(serviceType) ?? true)
        }
    }
    
    var uniqueId: String {
        return (clientId ?? "") + (flatId ?? "")
    }
    
    private enum CodingKeys: String, CodingKey {
        case clientId, clientName, contractName, flatOwner, contractOwner, hasGates, houseId, flatId, flatNumber, address
        case services, availableServices, lcab, roommates, hasPlog, doorCode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        clientId = try? container.decode(String.self, forKey: .clientId)
        clientName = try? container.decode(String.self, forKey: .clientName)
        contractName = try? container.decode(String.self, forKey: .contractName)
        
        flatOwner = Self.decodeFlag(.flatOwner, from: container)
        contractOwner = Self.decodeFlag(.contractOwner, from: container)
        hasGates = Self.decodeFlag(.hasGates, from: container)
        hasPlog = (try? container.decode(String.self, forKey: .hasPlog)) == "t"

        houseId = try? container.decode(String.self, forKey: .houseId)
        flatId = try? container.decode(String.self, forKey: .flatId)
        flatNumber = try? container.decode(String.self, forKey: .flatNumber)
        address = try container.decode(String.self, forKey: .address)
        services = try container.decode([String].self, forKey: .services)
        availableServices = try container.decodeIfPresent([APIServiceModel].self, forKey: .availableServices)
        lcab = try? container.decode(String.self, forKey: .lcab)
        doorCode = (try? container.decode(String.self, forKey: .doorCode)) ?? nil
        roommates = (try? container.decode([APIRoommate].self, forKey: .roommates)) ?? []
    }

    private static func decodeFlag(_ key: CodingKeys, from container: KeyedDecodingContainer<CodingKeys>) -> Bool? {
        switch try? container.decode(String.self, forKey: key) {
        case "t": return true
        case "f": return false
        default: return nil
        }
    }
    
}
