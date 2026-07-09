//
//  CameraStreamProvider.swift
//  SmartYard
//
//  Created by Александр Попов on 08.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import Foundation
import SmartYardVideoPlayer

final class CameraStreamProvider: PlayerResourceProviding {

    private struct CacheEntry {
        let resource: SYPlayerResource
        let expiresAt: Date
    }

    private let camerasById: [CameraID: CameraObject]
    private let ttl: TimeInterval

    private var cache: [CameraID: CacheEntry] = [:]
    private var inFlight: [CameraID: UUID] = [:]

    init(cameras: [CameraObject], ttl: TimeInterval = 20) {
        self.camerasById = cameras.dictionaryByIdKeepingFirst()
        self.ttl = ttl
    }

    // MARK: - PlayerResourceProviding

    func fetch(id: PlayerItemID, completion: @escaping (SYPlayerResource?) -> Void) {
        let cameraId = id
        cleanupExpired()

        if let cached = cache[cameraId], cached.expiresAt > Date() {
            touchCache(cameraId: cameraId)
            Logger.logDebug("fetch cacheHit id=\(cameraId)")
            completion(cached.resource)
            return
        }

        Logger.logDebug("fetch cacheMiss id=\(cameraId)")
        requestResource(cameraId: cameraId) { [weak self] resource in
            guard let self else { completion(resource); return }
            if let resource {
                self.store(resource: resource, cameraId: cameraId)
                self.warmupPlayback(resource: resource, cameraId: cameraId)
            }
            completion(resource)
        }
    }

    func prefetch(id: PlayerItemID) {
        let cameraId = id
        cleanupExpired()

        if let cached = cache[cameraId], cached.expiresAt > Date() {
            touchCache(cameraId: cameraId)
            prefetchHls(resource: cached.resource, cameraId: cameraId)
            warmupPlayback(resource: cached.resource, cameraId: cameraId)
            return
        }
        if inFlight[cameraId] != nil { return }

        Logger.logDebug("prefetch start id=\(cameraId)")
        requestResource(cameraId: cameraId) { [weak self] resource in
            guard let self else { return }
            guard let resource else { return }
            self.store(resource: resource, cameraId: cameraId)
            self.prefetchHls(resource: resource, cameraId: cameraId)
            self.warmupPlayback(resource: resource, cameraId: cameraId)
        }
    }

    func cancelPrefetch(id: PlayerItemID) {
        // Реальной отмены нет (updateURLAndExec callback-based),
        // делаем “логическую” отмену: сбросим request token — ответ будет проигнорирован.
        let cameraId = id
        Logger.logDebug("cancelPrefetch id=\(cameraId)")
        inFlight[cameraId] = nil
    }
}

private extension CameraStreamProvider {
    func requestResource(cameraId: CameraID, completion: @escaping (SYPlayerResource?) -> Void) {
        guard let camera = camerasById[cameraId] else {
            Logger.logError("requestResource missing camera id=\(cameraId)")
            completion(nil)
            return
        }

        let rid = UUID()
        inFlight[cameraId] = rid

        camera.updateURLAndExec { [weak self] urlString in
            guard let self else { return }
            guard inFlight[cameraId] == rid else {
                Logger.logDebug("requestResource ignored id=\(cameraId)")
                return
            } // “отменили/передумали”

            inFlight[cameraId] = nil

            guard let url = URL(string: urlString) else {
                Logger.logError("requestResource invalid URL id=\(cameraId)")
                completion(nil)
                return
            }

            var videos: [SYPlayerResourceVideo] = []
            if let whepURL = camera.whepURL {
                videos.append(SYPlayerResourceVideo(whepEndpointURL: whepURL))
            }
            videos.append(SYPlayerResourceVideo(url: url))

            let resource = SYPlayerResource(
                videos: videos,
                previewImage: URL(string: camera.previewURL),
                name: camera.name,
                videoType: .online,
                hasSound: camera.hasSound
            )

            completion(resource)
        }
    }

    func cleanupExpired() {
        let now = Date()
        cache = cache.filter { $0.value.expiresAt > now }
    }

    func store(resource: SYPlayerResource, cameraId: CameraID) {
        cache[cameraId] = CacheEntry(
            resource: resource,
            expiresAt: Date().addingTimeInterval(ttl)
        )
    }

    func touchCache(cameraId: CameraID) {
        guard let cached = cache[cameraId] else { return }
        store(resource: cached.resource, cameraId: cameraId)
    }

    func prefetchHls(resource: SYPlayerResource, cameraId: CameraID) {
        let urls = resource.videos.compactMap { video -> URL? in
            guard case .hls(let url) = video.source else {
                return nil
            }
            return url
        }
        guard !urls.isEmpty else { return }
        Logger.logDebug("prefetch hls id=\(cameraId) urls=\(urls.count)")
        SYPlayerConfig.shared.prefetch(urls: urls, maxCount: 3)
    }

    func warmupPlayback(resource: SYPlayerResource, cameraId: CameraID) {
        guard resource.videoType == .online else { return }

        let urls = resource.videos.map(\.url).filter { $0.pathExtension.lowercased() == "m3u8" }
        guard !urls.isEmpty else { return }
        urls.forEach { SYPlayerAssetWarmupStore.shared.warmup(url: $0) }
    }
}
