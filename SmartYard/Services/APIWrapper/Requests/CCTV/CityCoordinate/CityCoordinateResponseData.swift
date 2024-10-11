//
//  CityCoordinateResponseData.swift
//  SmartYard
//
//  Created by devcentra on 19.09.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import CoreLocation

struct CityCoordinateResponseData: Decodable, EmptyDataInitializable {
    
    let lat: Double?
    let lon: Double?
    let coordinate: CLLocationCoordinate2D?

    init() {
        lat = nil
        lon = nil
        coordinate = nil
    }

    private enum CodingKeys: String, CodingKey {
        case lat = "latitude"
        case lon = "longitude"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        lat = try container.decode(Double.self, forKey: .lat)
        lon = try container.decode(Double.self, forKey: .lon)

        guard let longitude = lon, let latitude = lat else {
            coordinate = nil
            return
        }
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
}
