//
//  APICCTV.swift
//  SmartYard
//
//  Created by admin on 25/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import CoreLocation
import SwifterSwift

struct APICCTV: Decodable {
    
    let houseId: Int?
    let id: Int
    let name: String
    let lat: String
    let lon: String
    let coordinate: CLLocationCoordinate2D
    let video: String
    let token: String
    let serverType: DVRServerType?
    let hlsMode: DVRHLSMode
    
    private enum CodingKeys: String, CodingKey {
        case houseId
        case id
        case name
        case lat
        case lon
        case url
        case token
        case serverType
        case hlsMode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        houseId = try? container.decode(Int.self, forKey: .houseId)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        lat = try container.decode(String.self, forKey: .lat)
        lon = try container.decode(String.self, forKey: .lon)
        
        guard let latDouble = Double(lat), let lonDouble = Double(lon) else {
            throw NSError.APIWrapperError.noDataError
        }
        
        coordinate = CLLocationCoordinate2D(latitude: latDouble, longitude: lonDouble)
        
        video = try container.decode(String.self, forKey: .url)
        token = try container.decode(String.self, forKey: .token)
        serverType = try? container.decode(DVRServerType.self, forKey: .serverType)
        hlsMode = (try? container.decode(DVRHLSMode.self, forKey: .hlsMode)) ?? .fmp4
    }
}

enum DVRServerType: String, Decodable, EmptyDataInitializable {
    case flussonic
    case nimble
    case macroscop
    case trassir
    case forpost
    
    init () {
        self = .flussonic
    }
}

enum DVRHLSMode: String, Decodable, EmptyDataInitializable {
    case mpegts
    case fmp4
    init () {
        self = .fmp4
    }
}
