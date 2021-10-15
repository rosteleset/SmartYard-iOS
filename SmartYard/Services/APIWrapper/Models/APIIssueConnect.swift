//
//  APIListConnect.swift
//  SmartYard
//
//  Created by Mad Brains on 17.03.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct APIIssueConnect: Decodable {
    
    let key: String
    let houseId: String?
    let address: String?
    let isDeliveredByCourier: Bool
    
    private enum CodingKeys: String, CodingKey {
        case key
        case houseId
        case address
        case courier
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        key = try container.decode(String.self, forKey: .key)
        houseId = try? container.decode(String.self, forKey: .houseId)
        address = try? container.decode(String.self, forKey: .address)

        let isCourierRawValue = try container.decode(String.self, forKey: .courier)
        
        switch isCourierRawValue {
        case "t": isDeliveredByCourier = true
        case "f": isDeliveredByCourier = false
        default: throw NSError.APIWrapperError.noDataError
        }
    }
}
