//
//  CheckPayResponseData.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 03.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct CheckPayResponseData: Decodable {
    
    let orderId: String?
    let status: Int
    let transactionId: Int?
    let comment: String?

    private enum CodingKeys: String, CodingKey {
        case orderId
        case status
        case transactionId
        case comment
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        orderId = try? container.decode(String.self, forKey: .orderId)
        status = try container.decode(Int.self, forKey: .status)
        transactionId = try? container.decode(Int.self, forKey: .transactionId)
        comment = try? container.decode(String.self, forKey: .comment)
    }
}
