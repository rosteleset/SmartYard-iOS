//
//  PlogRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 22.03.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//
import Foundation

struct PlogDaysRequest {
    
    let accessToken: String
    let forceRefresh: Bool
    let flatId: String
    let events: EventsFilter?
}

extension PlogDaysRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "flatId": flatId
        ]
        guard let events = events else {
            return params
        }
        
        switch events {
        case .all:
            break
        case .domophones:
            params["events"] = "1,2"
        case .keys:
            params["events"] = "3"
        case .faces:
            params["events"] = "5"
        case .phoneCall:
            params["events"] = "7,8"
        case .application:
            params["events"] = "4"
        case .code:
            params["events"] = "6"
        }
        return params
    }
    
}
