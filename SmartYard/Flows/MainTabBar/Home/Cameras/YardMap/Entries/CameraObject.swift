//
//  MapCamera.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import CoreLocation

struct CameraObject: Equatable {
    
    let id: Int
    let position: CLLocationCoordinate2D
    let cameraNumber: Int
    let name: String
    let video: String
    let token: String
    let serverType: DVRServerType
    
    var liveURL: String {
        switch self.serverType {
        case .nimble:
            return "\(video)/playlist.m3u8?wmsAuthSign=\(token)"
        default:
            return "\(video)/index.m3u8?token=\(token)"
        }
    }
    
    func archiveURL(urlComponents: String) -> String {
        switch self.serverType {
        case .nimble:
            return "\(video)/playlist_dvr_range-\(urlComponents).m3u8?wmsAuthSign=\(token)"
        default:
            return "\(video)/index-\(urlComponents).m3u8?token=\(token)"
        }
    }
    
    init(
        id: Int,
        position: CLLocationCoordinate2D,
        cameraNumber: Int,
        name: String,
        video: String,
        token: String,
        serverType: DVRServerType? = nil) {
            self.id = id
            self.position = position
            self.cameraNumber = cameraNumber
            self.name = name
            self.video = video
            self.token = token
            self.serverType = serverType ?? .flussonic
    }
    
}
