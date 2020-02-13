//
//  BaseAPIResponse.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct BaseAPIResponse<T: Decodable>: Decodable {
    
    let code: Int
    let name: String
    let message: String
    let data: T
    
}
