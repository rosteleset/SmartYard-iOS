//
//  CameraNumberController.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import SwifterSwift
import UIKit

final class CameraSectionController: SectionController {
    typealias Item = CameraViewCellModel

    private let events: OnlinePageEvents
    private weak var playback: OnlinePlaybackCoordinating?

    init(events: OnlinePageEvents, playback: OnlinePlaybackCoordinating) {
        self.events = events
        self.playback = playback
    }

    func registerCells(in collectionView: UICollectionView) {
        collectionView.register(cellWithClass: CameraViewCell.self)
    }

    func configureCell(
        at collectionView: UICollectionView,
        at indexPath: IndexPath,
        with item: CameraViewCellModel
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withClass: CameraViewCell.self,
            for: indexPath
        )
        cell.configure(with: item)
        return cell
    }

    func willDisplay(
        cell: UICollectionViewCell,
        at indexPath: IndexPath,
        item: CameraViewCellModel
    ) {
        guard let cell = cell as? CameraViewCell else {
            Logger.logError("willDisplay invalid cell type")
            return
        }
        playback?.willDisplay(cameraId: item.id, cell: cell)
    }

    func didEndDisplay(
        cell: UICollectionViewCell,
        at indexPath: IndexPath,
        item: CameraViewCellModel
    ) {
        guard let cell = cell as? CameraViewCell else {
            Logger.logError("didEndDisplay invalid cell type")
            return
        }
        playback?.didEndDisplay(cameraId: item.id, cell: cell)
    }

    func prefetch(items: [CameraViewCellModel]) {
        guard let playback else { return }
        let ids = Set(items.map(\.id))
        ids.forEach { playback.prefetch(id: $0) }
    }

    func cancelPrefetching(items: [CameraViewCellModel]) {
        guard let playback else { return }
        let ids = Set(items.map(\.id))
        ids.forEach { playback.cancelPrefetch(id: $0) }
    }
}
