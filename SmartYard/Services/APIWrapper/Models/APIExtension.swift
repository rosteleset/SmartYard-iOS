//
//  APIExtension.swift
//  SmartYard
//
//  Created by Александр Васильев on 15.03.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import Foundation
import UIKit

struct APIExtension: Decodable {
    
    let basePath: String
    let contentHTML: String
    
    private enum CodingKeys: String, CodingKey {
        case basePath
        case code
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        basePath = try container.decode(String.self, forKey: .basePath)
        contentHTML = try container.decode(String.self, forKey: .code)
    }
}
