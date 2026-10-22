//
//  GetPersonFacesRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 12.05.2021.
//  Copyright © 2021 Sesameware. All rights reserved.
//

struct GetPersonFacesRequest {
    
    let accessToken: String
    let forceRefresh: Bool
    let flatId: Int
    var groupId: Int?
    
}

extension GetPersonFacesRequest {
    
    var requestParameters: [String: Any] {
        var parameters: [String: Any] = ["flatId": flatId]
        if let groupId, groupId > 0 { parameters["groupId"] = groupId }
        return parameters
    }
    
}
