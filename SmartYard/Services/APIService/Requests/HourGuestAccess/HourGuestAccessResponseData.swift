//
//  HourGuestAccessResponseData.swift
//  SmartYard
//
//  Created by Mad Brains on 21.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct HourGuestAccessResponseData: Decodable {
    
    let allowDoorCode: String
    let doorCode: String?
    let cmc: String
    let voip: String
    let autoOpen: String
    let whiteRabbit: String
    
    private enum CodingKeys: String, CodingKey {
        case allowDoorCode = "allowDoorCode"
        case doorCode = "doorCode"
        case cmc = "CMS"
        case voip = "VoIP"
        case autoOpen = "autoOpen"
        case whiteRabbit = "whiteRabbit"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        allowDoorCode = try container.decode(String.self, forKey: .allowDoorCode)
        doorCode = try? container.decode(String.self, forKey: .doorCode)
        cmc = try container.decode(String.self, forKey: .cmc)
        voip = try container.decode(String.self, forKey: .voip)
        autoOpen = try container.decode(String.self, forKey: .autoOpen)
        whiteRabbit = try container.decode(String.self, forKey: .whiteRabbit)
    }
    
}
