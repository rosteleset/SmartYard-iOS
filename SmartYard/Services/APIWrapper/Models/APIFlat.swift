//
//  APIFlat.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 16.04.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct APIFlat: Decodable {
    
    let flatId: Int
    let flat: Int
    let frsDisabled: Bool?
    let contractOwner: Bool?
    let hasGates: Bool?
    let clientId: Int

    private enum CodingKeys: String, CodingKey {
        case flatId
        case flatNumber
        case frsEnabled
        case contractOwner
        case hasGates
        case clientId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        flatId = try container.decode(Int.self, forKey: .flatId)
        flat = try container.decode(Int.self, forKey: .flatNumber)
        clientId = try container.decode(Int.self, forKey: .clientId)

        let frsDisabledRawValue = try? container.decode(String.self, forKey: .frsEnabled)
        switch frsDisabledRawValue {
        case "f": frsDisabled = true
        case "t": frsDisabled = false
        default: frsDisabled = nil
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

    }
}
