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
    
    private enum CodingKeys: String, CodingKey {
        case id
        case url
        case token
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = Int(try container.decode(String.self, forKey: .id)) ?? 0
        url = try container.decode(String.self, forKey: .url)
        token = try container.decode(String.self, forKey: .token)
        
    }
    
}
