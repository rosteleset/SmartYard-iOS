//
//  APICCTV.swift
//  SmartYard
//
//  Created by admin on 25/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
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
    let preview: URL
    let video: URL
    
    private enum CodingKeys: String, CodingKey {
        case houseId
        case id
        case name
        case lat
        case lon
        case preview
        case video
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
        
        let previewString = try container.decode(String.self, forKey: .preview)
        preview = try URL(string: previewString).unwrapped(or: NSError.APIWrapperError.noDataError)
        
        let videoString = try container.decode(String.self, forKey: .video)
        video = try URL(string: videoString).unwrapped(or: NSError.APIWrapperError.noDataError)
    }
    
}
