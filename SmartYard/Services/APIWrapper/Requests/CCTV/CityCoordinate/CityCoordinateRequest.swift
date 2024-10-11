//
//  CityCoordinateRequest.swift
//  SmartYard
//
//  Created by devcentra on 19.09.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation

struct CityCoordinateRequest {
    
    let accessToken: String
    let forceRefresh: Bool
    let cityName: String?
    
}

extension CityCoordinateRequest {
    
    var requestParameters: [String: Any] {
        var params = [String: Any]()
        
        if let cityName = cityName {
            params["cityName"] = cityName
        }
        
        return params
    }
    
}
