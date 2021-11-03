//
//  ScreenshotHelper.swift
//  SmartYard
//
//  Created by admin on 25.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import AVKit

enum ScreenshotHelper {
    
    static func generateThumbnailFromVideoUrlAsync(
        url: URL,
        forTime time: CMTime,
        completion: ((CGImage?) -> Void)?
    ) {
        let asset = AVAsset(url: url)
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let completionHandler: AVAssetImageGeneratorCompletionHandler = { _, image, _, _, _ in
            completion?(image)
        }
        
        imageGenerator.generateCGImagesAsynchronously(
            forTimes: [NSValue(time: time)],
            completionHandler: completionHandler
        )
    }
    
}
