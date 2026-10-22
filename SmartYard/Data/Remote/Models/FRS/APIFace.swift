//
//  APIFace.swift
//  SmartYard
//
//  Created by Александр Васильев on 12.05.2021.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import Foundation
import UIKit

struct APIFace: Decodable, Hashable {
    let faceId: Int
    let image: String
    let groupId: Int?
    
    private enum CodingKeys: String, CodingKey {
        case faceId
        case image
        case groupId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        faceId = try container.decodePositiveIdentifier(forKey: .faceId)
        
        image = try container.decode(String.self, forKey: .image)
        groupId = try container.decodePositiveIdentifierIfPresent(forKey: .groupId)
    }

    init(faceId: Int, image: String, groupId: Int? = nil) {
        self.faceId = faceId
        self.image = image
        self.groupId = groupId.flatMap { $0 > 0 ? $0 : nil }
    }
}
