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
        
        let latRaw = try? container.decode(String.self, forKey: .lat)
        let lonRaw = try? container.decode(String.self, forKey: .lon)
        
        if let latRaw = latRaw, let lonRaw = lonRaw,
            let latDouble = Double(latRaw), let lonDouble = Double(lonRaw) {
            lat = latRaw
            lon = lonRaw
            coordinate = CLLocationCoordinate2D(latitude: latDouble, longitude: lonDouble)
        } else {
            lat = Constants.defaultMapCenterCoordinates.latitude.string
            lon = Constants.defaultMapCenterCoordinates.longitude.string
            coordinate = Constants.defaultMapCenterCoordinates
        }
        
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
