//
//  APIAttachment.swift
//  SmartYard
//
//  Created by devcentra on 07.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

struct APIAttachment: Decodable {

    let id: Int
    let messageId: Int
    let fileType: String
    let accountId: Int
    let extention: String?
    let dataUrl: String
    let thumbUrl: String?
    let fileSize: Int
    
    private enum CodingKeys: String, CodingKey {
        case id
        case messageId = "message_id"
        case fileType = "file_type"
        case accountId = "account_id"
        case extention
        case dataUrl = "data_url"
        case thumbUrl = "thumb_url"
        case fileSize = "file_size"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        messageId = try container.decode(Int.self, forKey: .messageId)
        fileType = try container.decode(String.self, forKey: .fileType)
        accountId = try container.decode(Int.self, forKey: .accountId)

        extention = try? container.decode(String.self, forKey: .extention)
        dataUrl = try container.decode(String.self, forKey: .dataUrl)
        thumbUrl = try? container.decode(String.self, forKey: .thumbUrl)

        fileSize = try container.decode(Int.self, forKey: .fileSize)
    }
}
