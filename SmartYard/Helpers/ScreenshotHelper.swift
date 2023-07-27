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
        imageType: SYImageType,
        completion: ((CGImage?) -> Void)?
    ) {
        switch imageType {
        case .jpeg:
            downloadJPEGImageWithCompletion(url, completion)
        case .mp4:
            downloadMP4ImageWithCompletion(url, completion, time)
        case .jpegLink:
            guard var urlBase = URLComponents(string: url.absoluteString) else {
                print(url.absoluteString)
                return
            }
            
            guard let queryItems = urlBase.queryItems else {
                print(url.absoluteString)
                return
            }
            
            var postParams: [String: Any] = [:]
            
            queryItems.forEach { postParams[$0.name] = $0.value }
            
            urlBase.query = nil
            
            guard let url = urlBase.url else {
                print(url.absoluteString)
                return
            }
            
            var request = URLRequest(url: url)
            
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "POST"
            request.httpBody = postParams.percentEncoded()
            
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    completion?(nil)
                    print(error.localizedDescription)
                    return
                }
                guard let data = data
                else {
                    completion?(nil)
                    print("Can't get image-link")
                    return
                }
                
                guard let jsonDict = try? JSONDecoder().decode([String: String].self, from: data),
                      let link = jsonDict["URL"],
                      let url = URL(string: link) else {
                    print("url \(data) is invalid")
                    return
                }
                
                downloadJPEGImageWithCompletion(url, completion)
            }
            task.resume()
        }
    }
    
    static func downloadMP4ImageWithCompletion(_ url: URL, _ completion: ((CGImage?) -> Void)?, _ time: CMTime) {
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
    
    static func downloadJPEGImageWithCompletion(_ url: URL, _ completion: ((CGImage?) -> Void)?) {
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion?(nil)
                print(error.localizedDescription)
                return
            }
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
            completion?(image)
            
        }
        task.resume()
    }
}
