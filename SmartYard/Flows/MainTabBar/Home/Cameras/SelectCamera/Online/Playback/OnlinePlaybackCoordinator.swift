//
//  OnlinePlaybackCoordinator.swift
//  SmartYard
//
//  Created by Александр Попов on 08.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import SmartYardVideoPlayer

protocol OnlinePlaybackCoordinating: AnyObject {
    func setSelectedCamera(id: CameraID, isMuted: Bool)
    func setCloseHandler(_ handler: (() -> Void)?)
    func updateCameraOrder(_ ids: [CameraID])
    func prefetch(id: CameraID)
    func cancelPrefetch(id: CameraID)
    func setMode(_ mode: SYPlayerUIMode)
    func willDisplay(cameraId: CameraID, cell: PlayerAttachable)
    func didEndDisplay(cameraId: CameraID, cell: PlayerAttachable)
    func stopHard()
}

import Foundation

final class OnlinePlaybackCoordinator {
    private let engine: SinglePlayerPlaybackCoordinator
    private let provider: PlayerResourceProviding

    private var cameraOrder: [CameraID] = []
    private var selectedCameraId: CameraID?
    private var selectedIsMuted: Bool = true

    init(provider: PlayerResourceProviding) {
        self.provider = provider
        self.engine = SinglePlayerPlaybackCoordinator(resourceProvider: provider)
    }

    private func prefetchNeighbors(for id: CameraID) {
        guard let idx = cameraOrder.firstIndex(of: id) else {
            Logger.logError("prefetchNeighbors missing id=\(id) orderCount=\(cameraOrder.count)")
            return
        }

        let prev = idx > 0 ? cameraOrder[idx - 1] : nil
        let next = (idx + 1 < cameraOrder.count) ? cameraOrder[idx + 1] : nil

        if let prev { provider.prefetch(id: prev) }
        if let next { provider.prefetch(id: next) }
    }
}

extension OnlinePlaybackCoordinator: OnlinePlaybackCoordinating {
    func willDisplay(cameraId: CameraID, cell: PlayerAttachable) {
        engine.willDisplay(id: cameraId, cell: cell)
    }

    func didEndDisplay(cameraId: CameraID, cell: PlayerAttachable) {
        engine.didEndDisplay(id: cameraId, cell: cell)
    }

    func updateCameraOrder(_ ids: [CameraID]) {
        cameraOrder = ids
        Logger.logDebug("updateCameraOrder count=\(ids.count)")
        // можно подрезать префетч после смены данных
        if let selectedCameraId { prefetchNeighbors(for: selectedCameraId) }
    }

    func setSelectedCamera(id: CameraID, isMuted: Bool) {
        selectedCameraId = id
        selectedIsMuted = isMuted
        Logger.logDebug("setSelectedCamera id=\(id) muted=\(isMuted)")
        engine.setSelected(id: id, isMuted: isMuted)
        prefetchNeighbors(for: id)
    }

    func stopHard() {
        engine.stopHard()
    }

    func setCloseHandler(_ handler: (() -> Void)?) {
        engine.setCloseHandler(handler)
    }

    func prefetch(id: CameraID) {
        provider.prefetch(id: id)
    }

    func cancelPrefetch(id: CameraID) {
        provider.cancelPrefetch(id: id)
    }

    func setMode(_ mode: SYPlayerUIMode) {
        engine.setMode(mode)
    }
}
