//
//  APICCTV.swift
//  SmartYard
//
//  Created by admin on 25/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct APICCTV: Decodable {
    
    let houseId: Int?
    let id: Int
    let name: String
    let lat: String
    let lon: String
    let preview: String
    let video: String
    
}
