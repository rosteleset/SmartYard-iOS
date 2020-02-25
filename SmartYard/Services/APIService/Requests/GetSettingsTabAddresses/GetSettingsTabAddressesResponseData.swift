//
//  GetVerifyedAddressesResponseData.swift
//  SmartYard
//
//  Created by Mad Brains on 25.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct GetSettingsTabAddressesResponseData: Decodable {
    
    let clientId: Int?
    let clientName: String?
    let contractName: String?
    let houseId: Int?
    let flatId: Int?
    let address: String
    let services: [String]
    
    private enum CodingKeys: String, CodingKey {
        case clientId = "clientId"
        case clientName = "clientName"
        case contractName = "contractName"
        case houseId = "houseId"
        case flatId = "flatId"
        case address = "address"
        case services = "services"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        clientId = try container.decode(Int.self, forKey: .clientId)
        clientName = try? container.decode(String.self, forKey: .clientName)
        contractName = try container.decode(String.self, forKey: .contractName)
        houseId = try container.decode(Int.self, forKey: .houseId)
        flatId = try container.decode(Int.self, forKey: .flatId)
        address = try container.decode(String.self, forKey: .address)
        services = try container.decode(Array.self, forKey: .services)
    }
    
}

