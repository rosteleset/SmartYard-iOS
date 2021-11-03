//
//  APIServiceModel.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct APIServiceModel: Decodable {
    
    let icon: String
    let title: String
    let description: String
    let isAvailableByDefault: Bool
    
    private enum CodingKeys: String, CodingKey {
        case icon
        case title
        case description
        case isAvailableByDefault = "byDefault"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        icon = try container.decode(String.self, forKey: .icon)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        
        let isAvailableByDefaultRawValue = try container.decode(String.self, forKey: .isAvailableByDefault)
        
        switch isAvailableByDefaultRawValue {
        case "t": isAvailableByDefault = true
        case "f": isAvailableByDefault = false
        default: throw NSError.APIWrapperError.noDataError
        }
    }
    
}
