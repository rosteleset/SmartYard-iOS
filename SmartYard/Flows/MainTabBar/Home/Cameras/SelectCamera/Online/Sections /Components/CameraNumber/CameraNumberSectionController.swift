//
//  CameraNumberController.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import SwifterSwift
import UIKit

final class CameraNumberSectionController: SectionController {
    typealias Item = CameraNumberCellViewModel

    private let events: OnlinePageEvents

    init(events: OnlinePageEvents) {
        self.events = events
    }

    func registerCells(in collectionView: UICollectionView) {
        collectionView.register(cellWithClass: CameraNumberCell.self)
    }

    func configureCell(
        at collectionView: UICollectionView,
        at indexPath: IndexPath,
        with item: CameraNumberCellViewModel
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withClass: CameraNumberCell.self,
            for: indexPath
        )
        cell.configure(with: item)
        return cell
    }

    func willDisplay(
        cell: UICollectionViewCell,
        at indexPath: IndexPath,
        item: CameraNumberCellViewModel
    ) {
        // (cell as? PortfolioCell)?.startAnimating()
    }

    func didSelect(
        item: CameraNumberCellViewModel,
        at indexPath: IndexPath
    ) {
        Logger.logDebug("didSelect cameraId=\(item.cameraId) index=\(indexPath.item)")
        events.didTapPreviewId.accept(item.cameraId)
    }
}
