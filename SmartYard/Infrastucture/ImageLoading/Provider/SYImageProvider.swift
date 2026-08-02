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
        cachePolicy: ImageCachePolicy,
        completion: ((UIImage?) -> Void)?
    ) {
        cancel(on: imageView)

        let options = kingfisherOptions(for: cachePolicy)

        switch source {
        case .remoteImage(let url):
            setRemoteImage(
                on: imageView,
                url: url,
                key: key,
                options: options,
                completion: completion
            )
        case .videoThumbnail(let url):
            setVideoThumbnail(
                on: imageView,
                url: url,
                key: key,
                options: options,
                completion: completion
            )
        }
    }

    private func setRemoteImage(
        on imageView: UIImageView,
        url: URL,
        key: String,
        options: KingfisherOptionsInfo,
        completion: ((UIImage?) -> Void)?
    ) {
        let resource = KF.ImageResource(downloadURL: url, cacheKey: key)
        imageView.kf.setImage(
            with: resource,
            placeholder: imageView.image,
            options: options
        ) { result in
            switch result {
            case .success(let value):
                DispatchQueue.main.async { completion?(value.image) }
            case .failure:
                completion?(nil)
            }
        }
    }

    private func setVideoThumbnail(
        on imageView: UIImageView,
        url: URL,
        key: String,
        options: KingfisherOptionsInfo,
        completion: ((UIImage?) -> Void)?
    ) {
        imageView.currentKey = key

        cache.retrieveImage(forKey: key, options: options) { [weak self, weak imageView] result in
            guard let self, let imageView else { return }
            guard imageView.currentKey == key else { return }

            if case .success(let value) = result, let image = value.image {
                imageView.image = image
                DispatchQueue.main.async { completion?(image) }
                return
            }

            let (shouldStart, token) = inFlight.add(key: key) { [weak imageView] image in
                guard let imageView else { return }
                guard imageView.currentKey == key else { return }

                if let image { imageView.image = image }
                completion?(image)
            }

            imageView.currentToken = token

            if !shouldStart { return }

            let timeoutWork = DispatchWorkItem { [weak inFlight] in
                inFlight?.complete(key: key, image: nil)
            }
            DispatchQueue.global(qos: .utility).asyncAfter(
                deadline: .now() + self.thumbnailTimeout,
                execute: timeoutWork
            )

            let cancellable = VideoThumbnailLoader.shared.loadThumbnail(
                from: url,
                timeSeconds: 0.0
            ) { [weak self] image in
                guard let self else { return }
                timeoutWork.cancel()

                if let image {
                    self.cache.store(
                        image,
                        forKey: key,
                        options: KingfisherParsedOptionsInfo(options),
                        toDisk: true
                    )
                }
                self.inFlight.complete(key: key, image: image)
            }

            inFlight.setCancel(key: key) {
                timeoutWork.cancel()
                cancellable.cancel()
            }
        }
    }

    private func kingfisherOptions(for cachePolicy: ImageCachePolicy) -> KingfisherOptionsInfo {
        switch cachePolicy {
        case .standard:
            return []
        case .refresh(let interval):
            return [
                .memoryCacheExpiration(.seconds(interval)),
                .memoryCacheAccessExtendingExpiration(.none),
                .diskCacheExpiration(.seconds(interval)),
                .diskCacheAccessExtendingExpiration(.none),
                .requestModifier(AnyModifier { request in
                    var request = request
                    request.cachePolicy = .reloadIgnoringLocalCacheData
                    return request
                })
            ]
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
