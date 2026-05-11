//
//  SYImageProvider.swift
//  SmartYard
//
//  Created by Александр Попов on 16.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit
import Kingfisher

final class SYImageProvider: ImageProviding {

    private let cache: ImageCache
    private let inFlight: InFlightImageRequests

    // Храним текущую video-task на imageView (weak key, чтобы не утекало)
    private let videoTasks = NSMapTable<UIImageView, VideoThumbnailTask>(
        keyOptions: .weakMemory, valueOptions: .strongMemory
    )

    private let thumbnailTimeout: TimeInterval

    init(
        cache: ImageCache = .default,
        inFlight: InFlightImageRequests = .shared,
        thumbnailTimeout: TimeInterval = 10
    ) {
        self.cache = cache
        self.inFlight = inFlight
        self.thumbnailTimeout = thumbnailTimeout
    }

    func setImage(
        on imageView: UIImageView,
        key: String,
        source: ImageSource,
        completion: ((UIImage?) -> Void)?
    ) {
        cancel(on: imageView)

        switch source {

        case .remoteImage(let url):
            // KF сам грузит, кэширует, отменяет
            imageView.kf.setImage(with: url) { result in
                switch result {
                case .success(let value):
                    DispatchQueue.main.async { completion?(value.image) }
                case .failure:
                    completion?(nil)
                }
            }

        case .videoThumbnail(let url):
            // 1) пробуем взять из KF cache (memory/disk, TTL уже применится сам)
            imageView.currentKey = key

            cache.retrieveImage(forKey: key) { [weak self, weak imageView] result in
                guard let self, let imageView else { return }
                guard imageView.currentKey == key else { return }


                switch result {
                case .success(let value):
                    if let image = value.image {
                        imageView.image = image
                        DispatchQueue.main.async { completion?(image) }
                        return
                    }
                case .failure:
                    break
                }

                // 2) мультикаст: подписываемся на результат
                let (shouldStart, token) = inFlight.add(key: key) { [weak imageView] image in
                    guard let imageView else { return }
                    guard imageView.currentKey == key else { return }

                    if let image { imageView.image = image }
                    completion?(image)
                }

                imageView.currentToken = token

                if !shouldStart { return }

                // Таймаут
                let timeoutWork = DispatchWorkItem { [weak inFlight] in
                    inFlight?.complete(key: key, image: nil)
                }
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + self.thumbnailTimeout, execute: timeoutWork)

                // Стартуем генерацию
                let cancellable = VideoThumbnailLoader.shared.loadThumbnail(from: url, timeSeconds: 0.0) { [weak self, weak imageView] image in
                    guard let self else { return }
                    timeoutWork.cancel()

                    // если cell уже переиспользовали — просто завершим inFlight (подписчики сами проверят currentKey)
                    if let image { self.cache.store(image, forKey: key, toDisk: true) }
                    self.inFlight.complete(key: key, image: image)
                }

                // Если все подписчики ушли — отменяем и task, и таймаут
                inFlight.setCancel(key: key) {
                    timeoutWork.cancel()
                    cancellable.cancel()
                }
            }
        }
    }

    func cancel(on imageView: UIImageView) {
        // remote (KF)
        imageView.kf.cancelDownloadTask()

        // video task (real cancel)
        videoTasks.object(forKey: imageView)?.cancel()
        videoTasks.removeObject(forKey: imageView)

        if let key = imageView.currentKey, let token = imageView.currentToken {
            inFlight.remove(key: key, token: token)
        }

        imageView.currentToken = nil
        imageView.currentKey = nil
    }
}
