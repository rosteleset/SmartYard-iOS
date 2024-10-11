//
//  UpdateSBPOrderResponseData.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 25.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct UpdateSBPOrderResponseData: Decodable {
    
    let success: Bool

    private enum CodingKeys: String, CodingKey {
        case transactionId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let transactionRawValue = try? container.decode(Int.self, forKey: .transactionId) {
            success = true
        } else {
            success = false
        }
    }
}
