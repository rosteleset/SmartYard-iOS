//
//  SingleVideoPlaybackCoordinator.swift
//  SmartYard
//
//  Created by Александр Попов on 08.01.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
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
    private var presentation: PlayerPresentation = .inline

    private weak var visibleSelectedCell: PlayerAttachable?
    private var visibleSelectedCellId: PlayerItemID?

    // защита от гонок fetch’ей
    private var requestId = UUID()

    init(
        playerController: SYPlayerController = SYPlayerController(),
        resourceProvider: PlayerResourceProviding,
        usesExternalFullscreenButton: Bool = false
    ) {
        self.playerController = playerController
        self.resourceProvider = resourceProvider
        playerController.setFullscreenButtonHidden(usesExternalFullscreenButton)
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
        guard cell.playerPresentation == presentation else { return }

        visibleSelectedCell = cell
        visibleSelectedCellId = id
        tryStartPlaybackIfPossible()
    }

    func didEndDisplay(id: PlayerItemID, cell: PlayerAttachable) {
        // A presentation change transfers ownership before the destination cell exists.
        // Late disappearance callbacks from the previous screen must not pause the stream.
        guard cell.playerPresentation == presentation else { return }
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
        presentation = mode == .fullscreen ? .fullscreen : .inline
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
        guard cell.playerPresentation == presentation else { return }

        if loadedResourceId == id {
            attachPlayer(to: cell)
            playerController.setMuted(selectedIsMuted)
            playerController.onAppear()
            return
        }

        let rid = UUID()
        requestId = rid

        resourceProvider.fetch(id: id) { [weak self] resource in
            guard let resource else { return }

            DispatchQueue.main.async { [weak self] in
                self?.apply(resource: resource, for: id, requestId: rid)
            }
        }
    }

    private func apply(resource: SYPlayerResource, for id: PlayerItemID, requestId: UUID) {
        // Fetches may complete off-main. Validate UI ownership only after returning to main.
        guard self.requestId == requestId,
              selectedId == id,
              let cell = visibleSelectedCell,
              cell.playerPresentation == presentation else { return }

        attachPlayer(to: cell)
        playerController.setMuted(selectedIsMuted)
        playerController.set(resource: resource)
        loadedResourceId = id
        playerController.onAppear()
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
