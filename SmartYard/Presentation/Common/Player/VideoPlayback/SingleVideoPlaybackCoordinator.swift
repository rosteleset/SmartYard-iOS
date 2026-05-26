//
//  SingleVideoPlaybackCoordinator.swift
//  SmartYard
//
//  Created by Александр Попов on 08.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import Foundation
import UIKit
import SmartYardVideoPlayer

final class SinglePlayerPlaybackCoordinator {

    private let playerController: SYPlayerController
    private let resourceProvider: PlayerResourceProviding

    private var selectedId: PlayerItemID?
    private var selectedIsMuted: Bool = true
    private var loadedResourceId: PlayerItemID?

    private weak var visibleSelectedCell: PlayerAttachable?
    private var visibleSelectedCellId: PlayerItemID?

    // защита от гонок fetch’ей
    private var requestId = UUID()

    init(
        playerController: SYPlayerController = SYPlayerController(),
        resourceProvider: PlayerResourceProviding
    ) {
        self.playerController = playerController
        self.resourceProvider = resourceProvider
    }

    // MARK: - Inputs

    func setSelected(id: PlayerItemID, isMuted: Bool) {
        let didChangeSelection = selectedId != id
        selectedId = id
        selectedIsMuted = isMuted
        requestId = UUID() // invalidate previous fetches, even if no visible cell yet

        if didChangeSelection {
            visibleSelectedCell = nil
            visibleSelectedCellId = nil
            loadedResourceId = nil
            playerController.onDisappear()
            playerController.detach(pause: false)
        }

        if !didChangeSelection {
            playerController.setMuted(isMuted)
        }

        tryStartPlaybackIfPossible()
    }

    func willDisplay(id: PlayerItemID, cell: PlayerAttachable) {
        guard id == selectedId else { return }

        visibleSelectedCell = cell
        visibleSelectedCellId = id
        tryStartPlaybackIfPossible()
    }

    func didEndDisplay(id: PlayerItemID, cell: PlayerAttachable) {
        guard visibleSelectedCell === cell else { return }
        guard visibleSelectedCellId == id else { return }

        visibleSelectedCell = nil
        visibleSelectedCellId = nil
        requestId = UUID() // “отменяем” in-flight

        playerController.onDisappear()
        playerController.detach(pause: false)
    }

    func stopHard() {
        visibleSelectedCell = nil
        visibleSelectedCellId = nil
        selectedId = nil
        loadedResourceId = nil
        requestId = UUID()
        playerController.stopHard()
    }

    func setCloseHandler(_ handler: (() -> Void)?) {
        playerController.setCloseHandler(handler)
    }

    func setMode(_ mode: SYPlayerUIMode) {
        playerController.setMode(mode)
    }

    func setRightAccessoryItems(_ items: [SYPlayerControlAccessoryItem]) {
        playerController.setRightAccessoryItems(items)
    }

    func updateRightAccessoryItem(
        id: String,
        _ update: (inout SYPlayerControlAccessoryItem) -> Void
    ) {
        playerController.updateRightAccessoryItem(id: id, update)
    }

    func removeAllRightAccessoryItems() {
        playerController.removeAllRightAccessoryItems()
    }

    func setControlsAutoHideEnabled(_ isEnabled: Bool) {
        playerController.setControlsAutoHideEnabled(isEnabled)
    }

    func toggleControlsVisibility() {
        playerController.toggleControlsVisibility()
    }

    // MARK: - Private

    private func tryStartPlaybackIfPossible() {
        guard let id = selectedId else { return }
        guard let cell = visibleSelectedCell else { return }

        if loadedResourceId == id {
            attachPlayer(to: cell)
            playerController.setMuted(selectedIsMuted)
            playerController.onAppear()
            return
        }

        let rid = UUID()
        requestId = rid

        resourceProvider.fetch(id: id) { [weak self] resource in
            guard let self else { return }
            guard self.requestId == rid else { return }
            guard self.selectedId == id else { return }
            guard let resource else { return }

            DispatchQueue.main.async {
                guard self.requestId == rid else { return }
                guard self.selectedId == id else { return }
                guard let cell = self.visibleSelectedCell else { return }

                self.attachPlayer(to: cell)
                self.playerController.setMuted(self.selectedIsMuted)
                self.playerController.set(resource: resource)
                self.loadedResourceId = id
                self.playerController.onAppear()
            }
        }
    }

    private func attachPlayer(to cell: PlayerAttachable) {
        guard let controlsAttachable = cell as? PlayerControlsAttachable else {
            playerController.attach(to: cell.playerContainerView, pauseBeforeDetach: false)
            return
        }

        playerController.attach(
            videoTo: cell.playerContainerView,
            controlsTo: controlsAttachable.playerControlsContainerView,
            pauseBeforeDetach: false
        )
    }

}
