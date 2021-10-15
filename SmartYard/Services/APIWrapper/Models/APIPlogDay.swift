//
//  APIPlog.swift
//  SmartYard
//
//  Created by Александр Васильев on 22.03.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

struct APIPlogDay: Decodable, Hashable {
    let day: Date //дата. Допустимые значения: "Y-m-d"
    let itemsCount: Int //количество событий
    
    private enum CodingKeys: String, CodingKey {
        case day
        case events
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let dayRawValue = try container.decode(String.self, forKey: .day)
        
        day = try dayRawValue.dateFromAPIString.unwrapped(or: NSError.APIWrapperError.noDataError)
        
        let eventsIntValue = try? container.decode(Int.self, forKey: .events)
        let eventsStringValue = try? container.decode(String.self, forKey: .events)
        
        guard let eventsRawValue = (eventsIntValue != nil) ? eventsIntValue : eventsStringValue?.int else {
            throw NSError.APIWrapperError.noDataError
        }
        
        itemsCount = eventsRawValue
    }
    
}
