//
//  CreateSBPOrderResponseData.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 25.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct CreateSBPOrderResponseData: Decodable {
    
    let id: Int

    private enum CodingKeys: String, CodingKey {
        case id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
    }
}
