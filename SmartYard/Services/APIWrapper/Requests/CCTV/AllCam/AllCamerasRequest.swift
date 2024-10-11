//
//  AllCamerasRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 07.05.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct AllCamerasRequest {
    
    let accessToken: String
    let forceRefresh: Bool
}

extension AllCamerasRequest {
    
    var requestParameters: [String: Any] {
        let params = [String: Any]()
        
        return params
    }
    
}
