//
//  VideoThumbnailConfiguration.swift
//  SmartYard
//
//  Created by admin on 09.07.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct VideoThumbnailConfiguration {
    
    let camera: CameraObject
    let period: ArchiveVideoPreviewPeriod
    let fallbackUrl: URL
    
    var identifier: String {
        return period.startDate.apiString
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
