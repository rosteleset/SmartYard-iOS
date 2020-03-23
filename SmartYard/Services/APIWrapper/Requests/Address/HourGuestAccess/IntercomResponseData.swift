//
//  HourGuestAccessResponseData.swift
//  SmartYard
//
//  Created by Mad Brains on 21.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct IntercomResponseData: Decodable {
    
    let allowDoorCode: Bool
    let doorCode: String?
    let cms: Bool
    let voip: Bool
    let autoOpen: Date
    let whiteRabbit: String
    
    private enum CodingKeys: String, CodingKey {
        case allowDoorCode
        case doorCode
        case cms = "CMS"
        case voip = "VoIP"
        case autoOpen
        case whiteRabbit
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let allowDoorCodeRawValue = try container.decode(String.self, forKey: .allowDoorCode)

        switch allowDoorCodeRawValue {
        case "t": allowDoorCode = true
        case "f": allowDoorCode = false
        default: throw NSError.APIServiceError.mappingError
        }
        
        doorCode = try? container.decode(String.self, forKey: .doorCode)
        
        let cmsRawValue = try container.decode(String.self, forKey: .cms)
        
        switch cmsRawValue {
        case "t": cms = true
        case "f": cms = false
        default: throw NSError.APIServiceError.mappingError
        }
        
        let voipRawValue = try container.decode(String.self, forKey: .voip)
        
        switch voipRawValue {
        case "t": voip = true
        case "f": voip = false
        default: throw NSError.APIServiceError.mappingError
        }
        
        let autoOpenRawValue = try container.decode(String.self, forKey: .autoOpen)
        autoOpen = try autoOpenRawValue.dateFromAPIString.unwrapped(or: NSError.APIServiceError.mappingError)
        
        whiteRabbit = try container.decode(String.self, forKey: .whiteRabbit)
    }
    
}
