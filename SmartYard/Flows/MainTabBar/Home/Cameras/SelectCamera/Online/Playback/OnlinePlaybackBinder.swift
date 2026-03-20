//
//  OnlinePlaybackBinder.swift
//  SmartYard
//
//  Created by Александр Попов on 28.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Отвечает за:
/// - updateCameraOrder
/// - setSelectedCamera
/// - setCloseHandler (inline -> fullscreen request)
/// - forceAttach выбранной камеры к видимой cell (и retry)
final class OnlinePlaybackBinder {

    // MARK: - Dependencies

    private weak var collectionView: UICollectionView?
    private let playback: OnlinePlaybackCoordinating

    // MARK: - State

    private var lastCameraOrder: [CameraID] = []
    private var latestState: OnlinePageState?

    private var lastForcedCameraId: CameraID?
    private weak var lastForcedCameraCell: CameraViewCell?

    private var onRequestFullscreen: ((CameraID) -> Void)?

    // MARK: - Init

    init(collectionView: UICollectionView, playback: OnlinePlaybackCoordinating) {
        self.collectionView = collectionView
        self.playback = playback
    }

    // MARK: - Bind

    func bind(
        state: Driver<OnlinePageState>,
        onRequestFullscreen: @escaping (CameraID) -> Void,
        disposeBag: DisposeBag
    ) {
        Logger.logDebug("bind")
        self.onRequestFullscreen = onRequestFullscreen

        // close handler always актуален и берёт latestState.selectedCameraId
        restoreCloseHandler()

        state
            .drive(with: self) { owner, state in
                owner.latestState = state

                // 1) order
                let order = state.cameras.map(\.id)
                if order != owner.lastCameraOrder {
                    owner.lastCameraOrder = order
                    Logger.logDebug("updateCameraOrder count=\(order.count)")
                    owner.playback.updateCameraOrder(order)
                }

                // 2) selected & muted
                guard let selected = state.cameras.first(where: { $0.id == state.selectedCameraId }) else {
                    Logger.logError(
                        "selected camera missing id=\(state.selectedCameraId) cameras=\(state.cameras.count)"
                    )
                    return
                }
                owner.playback.setSelectedCamera(id: selected.id, isMuted: selected.isMuted)

                // 3) ensure attach
                owner.forceAttachSelectedCameraIfNeeded(selectedId: selected.id, cameras: state.cameras)
            }
            .disposed(by: disposeBag)
    }

    /// Можно дернуть после fullscreen dismiss, если хочешь принудительно помочь attach.
    func restoreAfterFullscreen(selectedId: CameraID, retryCount: Int = 3) {
        Logger.logDebug("restoreAfterFullscreen id=\(selectedId) retries=\(retryCount)")
        guard let state = latestState else { return }
        forceAttachSelectedCamera(selectedId: selectedId, cameras: state.cameras, retryCount: retryCount)
    }

    func restoreCloseHandler() {
        Logger.logDebug("restoreCloseHandler")
        playback.setCloseHandler { [weak self] in
            guard let self, let id = self.latestState?.selectedCameraId else { return }
            self.onRequestFullscreen?(id)
        }
    }

    func restorePlayback() {
        Logger.logDebug("restorePlayback")
        lastForcedCameraId = nil
        lastForcedCameraCell = nil

        guard let state = latestState else { return }
        guard let selected = state.cameras.first(where: { $0.id == state.selectedCameraId }) else { return }

        playback.setSelectedCamera(id: selected.id, isMuted: selected.isMuted)
        forceAttachSelectedCamera(selectedId: selected.id, cameras: state.cameras, retryCount: 3)
    }
}

// MARK: - Private

private extension OnlinePlaybackBinder {

    func forceAttachSelectedCameraIfNeeded(selectedId: CameraID, cameras: [CameraViewModel]) {
        guard let collectionView else { return }
        guard !cameras.isEmpty else { return }

        // Если мы уже форсили этот id в эту же cell — не дёргаем снова.
        if lastForcedCameraId == selectedId, lastForcedCameraCell != nil {
            return
        }

        forceAttachSelectedCamera(selectedId: selectedId, cameras: cameras, retryCount: 1)
    }

    func forceAttachSelectedCamera(selectedId: CameraID, cameras: [CameraViewModel], retryCount: Int) {
        guard let collectionView else { return }
        guard !cameras.isEmpty else { return }
        guard let index = cameras.firstIndex(where: { $0.id == selectedId }) else {
            Logger.logError("forceAttach missing id=\(selectedId) cameras=\(cameras.count)")
            return
        }

        collectionView.layoutIfNeeded()

        let indexPath = IndexPath(item: index, section: 0)
        guard collectionView.indexPathsForVisibleItems.contains(indexPath) else { return }

        guard let cell = collectionView.cellForItem(at: indexPath) as? CameraViewCell else {
            guard retryCount > 0 else {
                Logger.logError("forceAttach cell not found id=\(selectedId) index=\(index)")
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.forceAttachSelectedCamera(selectedId: selectedId, cameras: cameras, retryCount: retryCount - 1)
            }
            return
        }

        lastForcedCameraId = selectedId
        lastForcedCameraCell = cell

        playback.willDisplay(cameraId: selectedId, cell: cell)
    }
}
