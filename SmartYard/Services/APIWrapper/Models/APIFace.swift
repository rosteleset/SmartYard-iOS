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
    let faceUrl: String
    let faceImage: UIImage?
    
    private enum CodingKeys: String, CodingKey {
        case faceId
        case faceImage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        faceId = try container.decode(Int.self, forKey: .faceId)
        faceUrl = try container.decode(String.self, forKey: .faceImage)
        
        faceImage = UIImage(base64URLString: faceUrl)
    }
}
