//
//  APIExtensionListItem.swift
//  SmartYard
//
//  Created by Александр Васильев on 15.03.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import Foundation
import UIKit

struct APIExtensionListItem: Decodable {
    
    let caption: String
    let iconURL: String
    let icon: UIImage?
    let extId: String
    let highlight: Bool
    let order: Int
    
    private enum CodingKeys: String, CodingKey {
        case caption
        case icon
        case extId
        case highlight
        case order
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        caption = try container.decode(String.self, forKey: .caption)
        iconURL = try container.decode(String.self, forKey: .icon)
        icon = UIImage(base64URLString: iconURL)
        extId = try container.decode(String.self, forKey: .extId)
        order = try container.decode(Int.self, forKey: .order)
        
        if let highlightRawValue = try? container.decode(String.self, forKey: .highlight),
           highlightRawValue == "t" {
            highlight = true
        } else {
            highlight = false
        }
        
        
    }
}
