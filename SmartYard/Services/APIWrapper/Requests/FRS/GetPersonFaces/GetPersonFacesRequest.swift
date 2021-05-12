//
//  GetPersonFacesRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 12.05.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct GetPersonFacesRequest {
    
    let accessToken: String
    
}

extension GetPersonFacesRequest {
    
    var requestParameters: [String: Any] {
        return [:]
    }
    
}
