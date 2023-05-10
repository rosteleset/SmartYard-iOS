//
//  APIAddress.swift
//  SmartYard
//
//  Created by admin on 04/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct APIAddress: Decodable {
    
    let houseId: String
    let address: String
    let doors: [APIDoor]
    let cctv: Int
    let hasPlog: Bool
    
    private enum CodingKeys: String, CodingKey {
        case houseId
        case address
        case doors
        case cctv
        case hasPlog
    }
    
    var uniqueId: String {
        return (houseId + address)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
//        houseId = try container.decode(String.self, forKey: .houseId)
        let hid = try container.decode(Int.self, forKey: .houseId)
        address = try container.decode(String.self, forKey: .address)
        
        houseId = String(hid) + "_" + address

        doors = (try? container.decode([APIDoor].self, forKey: .doors)) ?? []
        cctv = (try? container.decode(Int.self, forKey: .cctv)) ?? 0
        
        let hasPlogRawValue = (try? container.decode(String.self, forKey: .hasPlog)) ?? ""
        switch hasPlogRawValue {
        case "t": hasPlog = true
        default: hasPlog = false
        }
    }
    
}
