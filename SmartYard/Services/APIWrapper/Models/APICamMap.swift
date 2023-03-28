//
//  APICamMap.swift
//  SmartYard
//
//  Created by Александр Васильев on 27.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct APICamMap: Decodable {
    /// Id домофона
    let id: Int
    
    /// базовый url потока
    let url: String
    
    /// token от flussonic
    let token: String
    
    let frs: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id
        case url
        case token
        case frs
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        url = try container.decode(String.self, forKey: .url)
        token = try container.decode(String.self, forKey: .token)
        
        let isFrsValue = try container.decode(String.self, forKey: .frs)
        
        switch isFrsValue {
        case "t": frs = true
        case "f": frs = false
        default: frs = false
        }
    }
    
}
