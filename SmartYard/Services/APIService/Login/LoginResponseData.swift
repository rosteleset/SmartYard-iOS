//
//  LoginResponseData.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct LoginResponseData: Decodable {
    
    let accessToken: String
    let clientId: String
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "accessToken"
        case clientId = "client_id"
    }
    
}
