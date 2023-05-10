//
//  APIChatwoot.swift
//  SmartYard
//
//  Created by devcentra on 31.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation

struct APIChatwoot: Decodable {
    
    let id: Int
    let content: String?
    let messageType: Int
    let contentType: String
    let contentAttributes: [String]?
    let createdAt: Date
    let conversationId: Int
    let sender: APISender
    let attachments: [APIAttachment]

    private enum CodingKeys: String, CodingKey {
        case id
        case content
        case messageType = "message_type"
        case contentType = "content_type"
        case contentAttributes = "content_attributes"
        case createdAt = "created_at"
        case conversationId = "conversation_id"
        case sender
        case attachments
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        content = try? container.decode(String.self, forKey: .content)
        messageType = try container.decode(Int.self, forKey: .messageType)
        contentType = try container.decode(String.self, forKey: .contentType)

        contentAttributes = try? container.decode([String].self, forKey: .contentAttributes)
        
        createdAt = NSDate(timeIntervalSince1970: try container.decode(Double.self, forKey: .createdAt)) as Date
        conversationId = try container.decode(Int.self, forKey: .conversationId)

        sender = try container.decode(APISender.self, forKey: .sender)
        attachments = (try? container.decode([APIAttachment].self, forKey: .attachments)) ?? []

    }
    
}
