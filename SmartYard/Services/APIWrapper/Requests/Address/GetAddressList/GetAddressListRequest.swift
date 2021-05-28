//
//  GetAddressListRequest.swift
//  SmartYard
//
//  Created by admin on 25/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct GetAddressListRequest {
    
    let accessToken: String
    let forceRefresh: Bool
}

extension GetAddressListRequest {
    
    var requestParameters: [String: Any] {
        return [:]
    }
    
}
