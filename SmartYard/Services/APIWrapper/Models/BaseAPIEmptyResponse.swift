//
//  BaseAPIResponse.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct BaseAPIEmptyResponse<String: Decodable>: Decodable {
    
    let code: Int
    let name: String
    let message: String
    
}
