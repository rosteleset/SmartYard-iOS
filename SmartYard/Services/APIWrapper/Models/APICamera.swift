//
//  APICamera.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 07.05.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import CoreLocation
import SwifterSwift

struct APICamera: Decodable, Equatable {
    
    let id: Int
    let name: String
    let lat: Double
    let lon: Double
    let coordinate: CLLocationCoordinate2D
    let video: String
    let token: String

    static func == (lhs: APICamera, rhs: APICamera) -> Bool {
        return lhs.video == rhs.video
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case lat
        case lon
        case url
        case token
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        lat = try container.decode(Double.self, forKey: .lat)
        lon = try container.decode(Double.self, forKey: .lon)
        
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        video = try container.decode(String.self, forKey: .url)
        token = try container.decode(String.self, forKey: .token)
        
    }
}
