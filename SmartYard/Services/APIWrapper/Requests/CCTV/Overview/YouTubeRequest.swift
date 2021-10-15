//
//  YouTubeRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 18.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct YouTubeRequest {
    let accessToken: String
    let forceRefresh: Bool
    let id: Int?
}

extension YouTubeRequest {
    
    var requestParameters: [String: Any] {
        var params = [String: Any]()
        
        if let id = id {
            params["id"] = id
        }
        
        return params
    }
    
}
