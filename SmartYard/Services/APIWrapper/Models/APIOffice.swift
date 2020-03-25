//
//  APIOffice.swift
//  SmartYard
//
//  Created by Mad Brains on 25.03.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct APIOffice: Codable {
    
    let lat: Double
    let lon: Double
    let address: String
    let opening: String
    
    private enum CodingKeys: String, CodingKey {
        case lat
        case lon
        case address
        case opening
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        lat = try container.decode(Double.self, forKey: .lat)
        lon = try container.decode(Double.self, forKey: .lon)
        address = try container.decode(String.self, forKey: .address)
        opening = try container.decode(String.self, forKey: .opening)
    }
    
}
