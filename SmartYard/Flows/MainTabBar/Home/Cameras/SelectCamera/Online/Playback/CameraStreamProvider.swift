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
        self.camerasById = Dictionary(uniqueKeysWithValues: cameras.map { ($0.id, $0) })
        self.ttl = ttl
    }

    // MARK: - PlayerResourceProviding

    func fetch(id: PlayerItemID, completion: @escaping (SYPlayerResource?) -> Void) {
        let cameraId = id
        cleanupExpired()

        if let cached = cache[cameraId], cached.expiresAt > Date() {
            Logger.logDebug("fetch cacheHit id=\(cameraId)")
            completion(cached.resource)
            return
        }

        Logger.logDebug("fetch cacheMiss id=\(cameraId)")
        requestResource(cameraId: cameraId) { [weak self] resource in
            guard let self else { completion(resource); return }
            if let resource {
                cache[cameraId] = CacheEntry(resource: resource, expiresAt: Date().addingTimeInterval(self.ttl))
            }
            completion(resource)
        }
    }

    func prefetch(id: PlayerItemID) {
        let cameraId = id
        cleanupExpired()

        if let cached = cache[cameraId], cached.expiresAt > Date() {
            prefetchHls(resource: cached.resource, cameraId: cameraId)
            return
        }
        if inFlight[cameraId] != nil {
            return
        }

        Logger.logDebug("prefetch start id=\(cameraId)")
        requestResource(cameraId: cameraId) { [weak self] resource in
            guard let self else { return }
            guard let resource else { return }
            self.cache[cameraId] = CacheEntry(resource: resource, expiresAt: Date().addingTimeInterval(self.ttl))
            self.prefetchHls(resource: resource, cameraId: cameraId)
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

            let resource = SYPlayerResource(
                url: url,
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

    func prefetchHls(resource: SYPlayerResource, cameraId: CameraID) {
        let urls = resource.videos.map(\.url)
        guard !urls.isEmpty else { return }
        Logger.logDebug("prefetch hls id=\(cameraId) urls=\(urls.count)")
        SYPlayerConfig.shared.prefetch(urls: urls, maxCount: 3)
    }
}
