//
//  APIChat.swift
//  SmartYard
//
//  Created by devcentra on 03.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

struct APIChat: Decodable {
    
    let chat: String
    let name: String?
    let type: String?
    
    private enum CodingKeys: String, CodingKey {
        case chat
        case name
        case type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        chat = try container.decode(String.self, forKey: .chat)
        name = try? container.decode(String.self, forKey: .name)
        type = try? container.decode(String.self, forKey: .type)

    }
}
