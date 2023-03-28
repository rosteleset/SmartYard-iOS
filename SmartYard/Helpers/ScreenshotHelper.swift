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
        jpeg: Bool,
        completion: ((CGImage?) -> Void)?
    ) {
        if jpeg {
            let task = URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    completion?(nil)
                    print(error.localizedDescription)
                    return
                }
                print("Data of image  has arrived!")
                guard let data = data,
                      let provider = CGDataProvider(data: data as CFData),
                      let image = CGImage(
                        jpegDataProviderSource: provider,
                        decode: nil,
                        shouldInterpolate: true,
                        intent: CGColorRenderingIntent.defaultIntent
                      )
                else {
                    completion?(nil)
                    print("Can't create image")
                    return
                }
                print("Image created")
                completion?(image)
                
            }
            task.resume()
        } else {
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
    
}
