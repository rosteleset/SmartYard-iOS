//
//  VideoLoader.swift
//  SmartYard
//
//  Created by Александр Попов on 15.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import AVFoundation
import UIKit

final class VideoThumbnailLoader {
    static let shared = VideoThumbnailLoader()

    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "video.thumbnail.loader"
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 3
        return queue
    }()

    private init() {}

    /// Делает thumbnail (обычно быстро только если mp4 “удобный” для старта).
    /// Возвращает task для отмены.
    @discardableResult
    func loadThumbnail(
        from url: URL,
        timeSeconds: Double = 0.0,
        completion: @escaping (UIImage?) -> Void
    ) -> Cancellable {
        let task = VideoThumbnailTask()

        queue.addOperation {
            if task.isCancelled { return }

            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true

            // Для сетевых ассетов нулевая tolerance часто хуже.
            // Если хочешь строго “0.0” — оставь, но я бы начал так:
            generator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
            generator.requestedTimeToleranceAfter  = CMTime(seconds: 0.5, preferredTimescale: 600)

            task.bind(generator: generator)

            let time = CMTime(seconds: timeSeconds, preferredTimescale: 600)
            let nsTime = NSValue(time: time)

            generator.generateCGImagesAsynchronously(forTimes: [nsTime]) { _, cgImage, _, result, error in
                if task.isCancelled { return }

                let image: UIImage?
                if let cgImage, result == .succeeded {
                    image = UIImage(cgImage: cgImage)
                } else {
                    // error/result можно залогировать при дебаге
                    image = nil
                }

                DispatchQueue.main.async {
                    completion(image)
                }
            }
        }

        return task
    }
}
