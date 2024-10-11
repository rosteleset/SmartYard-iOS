//
//  APIPlace.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 07.05.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import CoreLocation
import SwifterSwift

struct APIPlace: Decodable {
    
    let houseId: Int?
    let address: String?
    let doorId: Int
    let type: DomophoneObjectType
    let name: String
    let domophoneId: String
    let hasPlog: Bool
    let flatId: Int?
    let doorcode: String?
    let flat: Int?
    let clientId: Int?
    let events: Int?
    let cctv: [APICCTV]

    private enum CodingKeys: String, CodingKey {
        case houseId
        case address
        case doorId
        case type = "icon"
        case name
        case domophoneId
        case hasPlog
        case flatId
        case doorCode
        case flatNumber
        case clientId
        case cctv
        case events
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        houseId = try? container.decode(Int.self, forKey: .houseId)
        address = try? container.decode(String.self, forKey: .address)
        
        doorId = try container.decode(Int.self, forKey: .doorId)
        
        let iconRawValue = try container.decode(String.self, forKey: .type)
        type = try DomophoneObjectType(rawValue: iconRawValue).unwrapped(or: NSError.APIWrapperError.noDataError)
        
        name = try container.decode(String.self, forKey: .name)
        domophoneId = try container.decode(String.self, forKey: .domophoneId)
        doorcode = try? container.decode(String.self, forKey: .doorCode)

        let hasPlogRawValue = (try? container.decode(String.self, forKey: .hasPlog)) ?? ""
        switch hasPlogRawValue {
        case "t": hasPlog = true
        default: hasPlog = false
        }
        
        flatId = try? container.decode(Int.self, forKey: .flatId)
        flat = try? container.decode(Int.self, forKey: .flatNumber)
        clientId = try? container.decode(Int.self, forKey: .clientId)
        
        events = try? container.decode(Int.self, forKey: .events)

        cctv = (try? container.decode([APICCTV].self, forKey: .cctv)) ?? []
    }
}
