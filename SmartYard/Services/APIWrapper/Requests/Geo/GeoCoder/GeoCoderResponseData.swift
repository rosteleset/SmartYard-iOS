//
//  GeoCoderResponseData.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct GeoCoderResponseData: Decodable {
    
    let lat: String
    let lon: String
    let address: String
    
}
