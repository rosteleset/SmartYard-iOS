//
//  VideoThumbnailConfiguration.swift
//  SmartYard
//
//  Created by admin on 09.07.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct VideoThumbnailConfiguration {
    
    let camera: CameraObject
    let period: ArchiveVideoHourPeriod
    let fallbackUrl: URL
    
    var identifier: String {
        return period.baseDate.adding(.hour, value: period.startHours).apiString
    }
    
    func thumbnailUrls(thumbnailsCount: Int, actualDuration: TimeInterval) -> [URL] {
        let thumbnailStrings = period.getThumbnailComponents(
            thumbnailsCount: thumbnailsCount,
            actualDuration: actualDuration
        )
        
        return thumbnailStrings.compactMap {
            URL(string: camera.video + $0 + "?token=\(camera.token)")
        }
    }
    
}
