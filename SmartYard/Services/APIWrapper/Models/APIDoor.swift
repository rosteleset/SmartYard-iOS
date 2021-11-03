//
//  APIDoor.swift
//  SmartYard
//
//  Created by admin on 25/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct APIDoor: Decodable {
    
    let domophoneId: String
    let doorId: Int
    let entrance: String?
    let type: DomophoneObjectType
    let name: String
    let blocked: String?
    let dst: String?
    
    private enum CodingKeys: String, CodingKey {
        case domophoneId
        case doorId
        case entrance
        case type = "icon"
        case name
        case blocked
        case dst
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        domophoneId = try container.decode(String.self, forKey: .domophoneId)
        doorId = try container.decode(Int.self, forKey: .doorId)
        entrance = try? container.decode(String.self, forKey: .entrance)
        
        let iconRawValue = try container.decode(String.self, forKey: .type)
        type = try DomophoneObjectType(rawValue: iconRawValue).unwrapped(or: NSError.APIWrapperError.noDataError)
        
        blocked = try? container.decode(String.self, forKey: .blocked)
        name = try container.decode(String.self, forKey: .name)
        dst = try? container.decode(String.self, forKey: .dst)
    }
    
}
