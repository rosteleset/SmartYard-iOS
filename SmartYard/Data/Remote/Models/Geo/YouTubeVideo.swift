//
//  YouTubeVideo.swift
//  SmartYard
//
//  Created by Александр Васильев on 18.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import CoreLocation
import SwifterSwift

struct YouTubeVideo: Decodable {
    
    let id: Int
    let eventTime: Date
    let title: String
    let description: String
    let thumbnailsDefault: String
    let thumbnailsMedium: String
    let thumbnailsHigh: String
    let url: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case eventTime
        case title
        case description
        case thumbnailsDefault
        case thumbnailsMedium
        case thumbnailsHigh
        case url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        
        let eventTimeRawValue = try container.decode(String.self, forKey: .eventTime)
        eventTime = try eventTimeRawValue.dateFromAPIString.unwrapped(or: NSError.APIWrapperError.noDataError)
        
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        thumbnailsHigh = try container.decode(String.self, forKey: .thumbnailsHigh)
        thumbnailsMedium = try container.decode(String.self, forKey: .thumbnailsMedium)
        thumbnailsDefault = try container.decode(String.self, forKey: .thumbnailsDefault)
        url = try container.decode(String.self, forKey: .url)
        
    }
    
}
