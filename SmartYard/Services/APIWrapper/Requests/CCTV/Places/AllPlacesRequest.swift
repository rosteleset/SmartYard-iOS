//
//  AllPlacesRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 07.05.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct AllPlacesRequest {
    
    let accessToken: String
    let forceRefresh: Bool
}

extension AllPlacesRequest {
    
    var requestParameters: [String: Any] {
        let params = [String: Any]()
        
        return params
    }
    
}
