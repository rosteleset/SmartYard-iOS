//
//  OnlineFullscreenViewController.swift
//  SmartYard
//
//  Created by Александр Попов on 24.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit
import SwifterSwift

final class OnlineFullscreenViewController: BaseViewController {

    // MARK: - Dependencies

    private let cameras: [CameraViewModel]
    private let playback: OnlinePlaybackCoordinating
    private let onDismiss: (CameraID) -> Void

    // MARK: - State

    private var currentIndex: Int
    private var lastBoundsSize: CGSize = .zero
    private var didInitialScroll = false
    private var didNotifyDismiss = false

    // MARK: - UI

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.decelerationRate = .fast
        cv.dataSource = self
        cv.delegate = self

        cv.register(cellWithClass: OnlineFullscreenCameraCell.self)
        return cv
    }()

    // MARK: - Init

    init(
        cameras: [CameraViewModel],
        initialCameraId: CameraID,
        playback: OnlinePlaybackCoordinating,
        onDismiss: @escaping (CameraID) -> Void
    ) {
        self.cameras = cameras
        self.playback = playback
        self.onDismiss = onDismiss
        self.currentIndex = cameras.firstIndex(where: { $0.id == initialCameraId }) ?? 0
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.logDebug("viewDidLoad cameras=\(cameras.count) startIndex=\(currentIndex)")
        if cameras.isEmpty {
            Logger.logError("viewDidLoad empty cameras")
        }
        view.backgroundColor = .black
        view.addSubview(collectionView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Logger.logDebug("viewDidAppear")
        playback.setCloseHandler { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
        updateLayoutIfNeeded()

        if !didInitialScroll {
            didInitialScroll = true
            scrollToIndex(currentIndex, animated: false)
            updateSelection(index: currentIndex, force: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Logger.logDebug("viewWillDisappear beingDismissed=\(isBeingDismissed)")
        playback.setCloseHandler(nil)

        if isBeingDismissed {
            notifyDismiss()
        }
    }
}

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
        cell.setPagingPanGesture(collectionView.panGestureRecognizer)
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

        cell.resetZoom()

        let camera = cameras[indexPath.item]
        playback.didEndDisplay(cameraId: camera.id, cell: cell)
    }
}

// MARK: - UIScrollViewDelegate

extension OnlineFullscreenViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentIndexIfNeeded()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateCurrentIndexIfNeeded()
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentIndexIfNeeded(force: true)
    }
}

// MARK: - Private

private extension OnlineFullscreenViewController {
    func updateLayoutIfNeeded() {
        let size = collectionView.bounds.size
        guard size != .zero else { return }

        if size != lastBoundsSize,
           let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            lastBoundsSize = size
            layout.itemSize = size
            layout.invalidateLayout()
            collectionView.layoutIfNeeded()
            let offsetX = CGFloat(currentIndex) * size.width
            collectionView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
            collectionView.layoutIfNeeded()
            updateSelection(index: currentIndex, force: true)
        }
    }

    func scrollToIndex(_ index: Int, animated: Bool) {
        guard cameras.indices.contains(index) else { return }
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }

    func updateCurrentIndexIfNeeded(force: Bool = false) {
        guard !cameras.isEmpty, collectionView.bounds.width > 0 else { return }
        let rawIndex = Int(round(collectionView.contentOffset.x / collectionView.bounds.width))
        let clamped = max(0, min(rawIndex, cameras.count - 1))
        updateSelection(index: clamped, force: force)
    }

    func updateSelection(index: Int, force: Bool) {
        guard cameras.indices.contains(index) else { return }
        if !force, index == currentIndex { return }

        currentIndex = index
        let camera = cameras[index]
        Logger.logDebug("updateSelection id=\(camera.id) index=\(index)")
        playback.setSelectedCamera(id: camera.id, isMuted: camera.isMuted)

        let indexPath = IndexPath(item: index, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? OnlineFullscreenCameraCell {
            playback.willDisplay(cameraId: camera.id, cell: cell)
        }
    }

    func notifyDismiss() {
        guard !didNotifyDismiss else { return }
        didNotifyDismiss = true

        guard cameras.indices.contains(currentIndex) else { return }
        let cameraId = cameras[currentIndex].id
        Logger.logDebug("notifyDismiss id=\(cameraId)")
        onDismiss(cameraId)

        let indexPath = IndexPath(item: currentIndex, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? OnlineFullscreenCameraCell {
            playback.didEndDisplay(cameraId: cameraId, cell: cell)
        }
    }
}
