//
//  CheckOffertaRequest.swift
//  SmartYard
//
//  Created by devcentra on 16.02.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

struct CheckOffertaRequest {
    
    let accessToken: String
    let login: String?
    let password: String?
    let houseId: String?
    let flat: String?
}

extension CheckOffertaRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [:]
        
        if let login = login {
            params["login"] = login
        }
        if let password = password {
            params["password"] = password
        }
        if let houseId = houseId {
            params["houseId"] = houseId
        }
        if let flat = flat {
            params["flat"] = flat
        }

        return params
    }
    
}
