//
//  BaseAPIResponse.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct BaseAPIResponse: Decodable {
    
    let code: Int
    let name: String
    let message: String
    
}
