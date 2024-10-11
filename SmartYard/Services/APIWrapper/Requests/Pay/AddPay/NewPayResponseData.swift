//
//  NewPayResponseData.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 03.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct NewPayResponseData: Decodable {
    
    let orderId: Int
    let formUrl: String

    private enum CodingKeys: String, CodingKey {
        case orderId
        case formUrl
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        orderId = try container.decode(Int.self, forKey: .orderId)
        formUrl = try container.decode(String.self, forKey: .formUrl)
    }
}
