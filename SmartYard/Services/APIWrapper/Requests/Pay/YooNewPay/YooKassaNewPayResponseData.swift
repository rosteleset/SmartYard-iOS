//
//  YooKassaNewPayResponseData.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 16.08.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct YooKassaNewPayResponseData: Decodable {
    
    let id: Int
    let status: Int
    let orderId: String?
    let transactionId: Int?
    let comment: String?
    let confirmationUrl: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case status
        case orderId
        case transactionId
        case comment
        case confirmationUrl
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        status = try container.decode(Int.self, forKey: .status)
        
        orderId = try? container.decode(String.self, forKey: .orderId)
        transactionId = try? container.decode(Int.self, forKey: .transactionId)
        comment = try? container.decode(String.self, forKey: .comment)
        confirmationUrl = try? container.decode(String.self, forKey: .confirmationUrl)
    }
}
