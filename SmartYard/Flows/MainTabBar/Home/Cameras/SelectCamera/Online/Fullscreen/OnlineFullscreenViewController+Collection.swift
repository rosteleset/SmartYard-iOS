// Created by Александр Попов. Copyright © 2026 Sesameware.

import UIKit
import SwifterSwift
import SnapKit
import SmartYardVideoPlayer

// MARK: - UICollectionViewDataSource

extension OnlineFullscreenViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        cameras.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withClass: OnlineFullscreenCameraCell.self,
            for: indexPath
        )
        let camera = cameras[indexPath.item]
        cell.configure(cameraId: camera.id, previewURL: camera.resource.previewImage)
        cell.onRequestExitFullscreen = { [weak self] in self?.dismiss(animated: true) }
        cell.setPagingPanGesture(collectionView.panGestureRecognizer)
        cell.onPagingHandoffStateChanged = { [weak self] isActive in
            self?.setPagingHandoffActive(isActive)
        }
        cell.onContentTap = { [weak self] in
            self?.playback.toggleControlsVisibility()
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension OnlineFullscreenViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let cell = cell as? OnlineFullscreenCameraCell else { return }
        guard cameras.indices.contains(indexPath.item) else { return }
        guard !isPagingHandoffActive else {
            return
        }

        if indexPath.item != currentIndex {
            cell.resetZoomAndCenter()
        }

        let camera = cameras[indexPath.item]
        playback.willDisplay(cameraId: camera.id, cell: cell)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let cell = cell as? OnlineFullscreenCameraCell else { return }
        guard cameras.indices.contains(indexPath.item) else { return }
        guard !isPagingHandoffActive else {
            return
        }

        cell.resetZoom()

        let camera = cameras[indexPath.item]
        playback.didEndDisplay(cameraId: camera.id, cell: cell)
    }
}

// MARK: - UIScrollViewDelegate

extension OnlineFullscreenViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard !isPagingHandoffActive else { return }
        updateCurrentIndexIfNeeded()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !isPagingHandoffActive else { return }
        if !decelerate {
            updateCurrentIndexIfNeeded()
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard !isPagingHandoffActive else { return }
        updateCurrentIndexIfNeeded(force: true)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension OnlineFullscreenViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === dismissPanGesture,
              !isSwipeDismissInProgress,
              !isPagingHandoffActive,
              let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
              let currentCell = collectionView.cellForItem(
                  at: IndexPath(item: currentIndex, section: 0)
              ) as? OnlineFullscreenCameraCell,
              !currentCell.isZoomed
        else {
            return false
        }

        let velocity = panGesture.velocity(in: view)
        return abs(velocity.y) > abs(velocity.x)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        gestureRecognizer === dismissPanGesture || otherGestureRecognizer === dismissPanGesture
    }
}
