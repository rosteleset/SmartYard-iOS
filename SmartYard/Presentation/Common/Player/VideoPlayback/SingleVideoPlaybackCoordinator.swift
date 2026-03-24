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

    private weak var visibleSelectedCell: PlayerAttachable?

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
        selectedId = id
        selectedIsMuted = isMuted
        requestId = UUID() // invalidate previous fetches, even if no visible cell yet
        tryStartPlaybackIfPossible()
    }

    func willDisplay(id: PlayerItemID, cell: PlayerAttachable) {
        guard id == selectedId else { return }

        visibleSelectedCell = cell
        tryStartPlaybackIfPossible()
    }

    func didEndDisplay(id _: PlayerItemID, cell: PlayerAttachable) {
        guard visibleSelectedCell === cell else { return }

        visibleSelectedCell = nil
        requestId = UUID() // “отменяем” in-flight

        playerController.onDisappear()
        playerController.detach(pause: false)
    }

    func stopHard() {
        visibleSelectedCell = nil
        selectedId = nil
        requestId = UUID()
        playerController.stopHard()
    }

    func setCloseHandler(_ handler: (() -> Void)?) {
        playerController.setCloseHandler(handler)
    }

    func setMode(_ mode: SYPlayerUIMode) {
        playerController.setMode(mode)
    }

    // MARK: - Private

    private func tryStartPlaybackIfPossible() {
        guard let id = selectedId else { return }
        guard visibleSelectedCell != nil else { return }

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

                self.playerController.attach(to: cell.playerContainerView, pauseBeforeDetach: false)
                self.playerController.setMuted(self.selectedIsMuted)
                self.playerController.set(resource: resource)
                self.playerController.onAppear()
            }
        }
    }
}
