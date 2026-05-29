//
//  PlogRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 22.03.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//
import Foundation

struct PlogRequest {
    
    let accessToken: String
    let forceRefresh: Bool
    let flatId: String
    let fromDate: Date
}

struct TrackEventRequest {
    let accessToken: String
    let flatId: Int
    let eventType: Int
    let eventDetail: String
    let comments: String
}

struct UntrackEventRequest {
    let accessToken: String
    let watcherId: Int
}

struct GetTrackedEventsRequest {
    let accessToken: String
    let flatId: Int
}

extension PlogRequest {
    
    var requestParameters: [String: Any] {
        let params: [String: Any] = [
            "flatId": flatId,
            "day": fromDate.apiShortString
        ]
        
        return params
    }
    
}

extension TrackEventRequest {
    var requestParameters: [String: Any] {
        return [
            "flatId": flatId,
            "eventType": eventType,
            "eventDetail": eventDetail,
            "comments": comments
        ]
    }
}

extension UntrackEventRequest {
    var requestParameters: [String: Any] {
        return [
            "watcherId": watcherId
        ]
    }
}

extension GetTrackedEventsRequest {
    var requestParameters: [String: Any] {
        return [
            "flatId": flatId
        ]
    }
}
