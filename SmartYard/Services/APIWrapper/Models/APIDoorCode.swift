//
//  APIDoorCode.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 16.04.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct APIDoorCode: Decodable {
    
    let domophoneId: String
    let flatId: Int
    let doorcode: String?

    private enum CodingKeys: String, CodingKey {
        case domophoneId
        case flatId
        case doorCode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        domophoneId = try container.decode(String.self, forKey: .domophoneId)
        flatId = try container.decode(Int.self, forKey: .flatId)
        doorcode = try? container.decode(String.self, forKey: .doorCode)
    }
}
