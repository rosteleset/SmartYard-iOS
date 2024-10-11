//
//  APIIntercoms.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 16.04.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation
import CoreLocation

struct APIIntercoms: Decodable, Equatable {
    
    let doors: [APIDoor]
    let doorcode: APIDoorCode?
    let flats: [APIFlat]
    let events: Int
    let id: Int
    let name: String
    let coordinate: CLLocationCoordinate2D
    let video: String
    let token: String

    static func == (lhs: APIIntercoms, rhs: APIIntercoms) -> Bool {
        return lhs.video == rhs.video
    }
    
    private enum CodingKeys: String, CodingKey {
        case doors
        case doorcode = "code"
        case flats
        case events
        case id
        case name
        case lat
        case lon
        case url
        case token
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        doors = (try? container.decode([APIDoor].self, forKey: .doors)) ?? []
        doorcode = try? container.decode(APIDoorCode.self, forKey: .doorcode)
        flats = (try? container.decode([APIFlat].self, forKey: .flats)) ?? []

        events = try container.decode(Int.self, forKey: .events)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        let lat = try container.decode(Double.self, forKey: .lat)
        let lon = try container.decode(Double.self, forKey: .lon)
        
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        video = try container.decode(String.self, forKey: .url)
        token = try container.decode(String.self, forKey: .token)
    }
    
}
