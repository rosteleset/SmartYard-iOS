//
//  APICCTV.swift
//  SmartYard
//
//  Created by admin on 25/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import CoreLocation
import SwifterSwift

struct APICCTV: Decodable, Equatable {
    
    let houseId: Int?
    let id: Int
    let name: String
    let lat: Double
    let lon: Double
    let coordinate: CLLocationCoordinate2D
    let video: String
    let token: String
    let doors: [APIDoor]
    let flatIds: [String?]
    let status: Bool?

    static func == (lhs: APICCTV, rhs: APICCTV) -> Bool {
        return lhs.video == rhs.video
    }
    
    private enum CodingKeys: String, CodingKey {
        case houseId
        case id
        case name
        case lat
        case lon
        case url
        case token
        case doors
        case flatIds
        case status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        houseId = try? container.decode(Int.self, forKey: .houseId)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        lat = try container.decode(Double.self, forKey: .lat)
        lon = try container.decode(Double.self, forKey: .lon)
        
//        guard let latDouble = Double(lat), let lonDouble = Double(lon) else {
//            throw NSError.APIWrapperError.noDataError
//        }
        
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        video = try container.decode(String.self, forKey: .url)
        token = try container.decode(String.self, forKey: .token)
        
        doors = (try? container.decode([APIDoor].self, forKey: .doors)) ?? []
        flatIds = (try? container.decode([String].self, forKey: .flatIds)) ?? []
        
        status = try? container.decode(Bool.self, forKey: .status)
    }
}
