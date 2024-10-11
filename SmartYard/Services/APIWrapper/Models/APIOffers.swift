//
//  APIOffers.swift
//  SmartYard
//
//  Created by devcentra on 16.02.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation
import UIKit

struct APIOffers: Decodable, Hashable {
    let name: String
    let url: String
    
    private enum CodingKeys: String, CodingKey {
        case name
        case url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(String.self, forKey: .url)
    }
}
