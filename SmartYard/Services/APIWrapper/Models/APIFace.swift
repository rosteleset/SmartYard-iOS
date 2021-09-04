//
//  APIFace.swift
//  SmartYard
//
//  Created by Александр Васильев on 12.05.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

struct APIFace: Decodable, Hashable {
    let faceId: Int
    let image: String
    
    private enum CodingKeys: String, CodingKey {
        case faceId
        case image
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guard let faceId = Int(try container.decode(String.self, forKey: .faceId)) else {
            throw NSError.APIWrapperError.noDataError
        }
        self.faceId = faceId
        
        image = try container.decode(String.self, forKey: .image)
    }
}
