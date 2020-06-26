//
//  ScreenshotHelper.swift
//  SmartYard
//
//  Created by admin on 25.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import AVKit

enum ScreenshotHelper {
    
    static func generateThumbnailFromVideoUrl(url: URL, forTime time: CMTime) -> UIImage? {
        let asset = AVAsset(url: url)
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        var actualTime: CMTime = .zero
        
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
            let image = UIImage(cgImage: imageRef)
            return image
        } catch {
            return nil
        }
    }
    
}
