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

    private var lastForcedIndex: Int?
    private weak var lastForcedCameraCell: CameraViewCell?

    private var onRequestFullscreen: ((Int) -> Void)?

    // MARK: - Init

    init(collectionView: UICollectionView, playback: OnlinePlaybackCoordinating) {
        self.collectionView = collectionView
        self.playback = playback
    }

    // MARK: - Bind

    func bind(
        state: Driver<OnlinePageState>,
        onRequestFullscreen: @escaping (Int) -> Void,
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
                guard state.cameras.indices.contains(state.selectedIndex) else {
                    Logger.logError(
                        "selected camera missing index=\(state.selectedIndex) cameras=\(state.cameras.count)"
                    )
                    return
                }
                let selected = state.cameras[state.selectedIndex]
                owner.playback.setSelectedCamera(id: selected.id, isMuted: selected.isMuted)

                // 3) ensure attach
                owner.forceAttachSelectedCameraIfNeeded(selectedIndex: state.selectedIndex, cameras: state.cameras)
            }
            .disposed(by: disposeBag)
    }

    /// Можно дернуть после fullscreen dismiss, если хочешь принудительно помочь attach.
    func restoreAfterFullscreen(selectedIndex: Int, retryCount: Int = 3) {
        Logger.logDebug("restoreAfterFullscreen index=\(selectedIndex) retries=\(retryCount)")
        guard let state = latestState else { return }
        forceAttachSelectedCamera(selectedIndex: selectedIndex, cameras: state.cameras, retryCount: retryCount)
    }

    func restoreCloseHandler() {
        Logger.logDebug("restoreCloseHandler")
        playback.setCloseHandler { [weak self] in
            guard let self, let index = self.latestState?.selectedIndex else { return }
            self.onRequestFullscreen?(index)
        }
    }

    func restorePlayback() {
        Logger.logDebug("restorePlayback")
        lastForcedIndex = nil
        lastForcedCameraCell = nil

        guard let state = latestState else { return }
        guard state.cameras.indices.contains(state.selectedIndex) else { return }
        let selected = state.cameras[state.selectedIndex]

        playback.setSelectedCamera(id: selected.id, isMuted: selected.isMuted)
        forceAttachSelectedCamera(selectedIndex: state.selectedIndex, cameras: state.cameras, retryCount: 3)
    }
}

// MARK: - Private

private extension OnlinePlaybackBinder {

    func forceAttachSelectedCameraIfNeeded(selectedIndex: Int, cameras: [CameraViewModel]) {
        guard let collectionView else { return }
        guard !cameras.isEmpty else { return }

        // Если мы уже форсили этот index в эту же cell — не дёргаем снова.
        if lastForcedIndex == selectedIndex, lastForcedCameraCell != nil {
            return
        }

        forceAttachSelectedCamera(selectedIndex: selectedIndex, cameras: cameras, retryCount: 1)
    }

    func forceAttachSelectedCamera(selectedIndex: Int, cameras: [CameraViewModel], retryCount: Int) {
        guard let collectionView else { return }
        guard !cameras.isEmpty else { return }
        guard cameras.indices.contains(selectedIndex) else {
            Logger.logError("forceAttach missing index=\(selectedIndex) cameras=\(cameras.count)")
            return
        }

        collectionView.layoutIfNeeded()

        let indexPath = IndexPath(item: selectedIndex, section: 0)
        guard collectionView.indexPathsForVisibleItems.contains(indexPath) else { return }

        guard let cell = collectionView.cellForItem(at: indexPath) as? CameraViewCell else {
            guard retryCount > 0 else {
                Logger.logError("forceAttach cell not found index=\(selectedIndex)")
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.forceAttachSelectedCamera(
                    selectedIndex: selectedIndex,
                    cameras: cameras,
                    retryCount: retryCount - 1
                )
            }
            return
        }

        lastForcedIndex = selectedIndex
        lastForcedCameraCell = cell

        playback.willDisplay(cameraId: cameras[selectedIndex].id, cell: cell)
    }
}
