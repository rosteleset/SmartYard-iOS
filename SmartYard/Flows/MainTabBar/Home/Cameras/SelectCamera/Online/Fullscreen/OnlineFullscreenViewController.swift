//
//  OnlineFullscreenViewController.swift
//  SmartYard
//
//  Created by Александр Попов on 24.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit
import SmartYardVideoPlayer

struct OnlineFullscreenAccessAction {
    let isOpened: Bool
    let open: (@escaping (Bool) -> Void) -> Void
}

final class OnlineFullscreenViewController: BaseViewController {

    // MARK: - Dependencies

    private let cameras: [CameraViewModel]
    private let playback: OnlinePlaybackCoordinating
    private let accessActions: [Int: OnlineFullscreenAccessAction]
    private let onDismiss: (Int) -> Void

    // MARK: - State

    private var currentIndex: Int
    private var lastBoundsSize: CGSize = .zero
    private var didInitialScroll = false
    private var didNotifyDismiss = false
    private var isOpeningAccess = false
    private var isPagingHandoffActive = false
    private var accessOpenedStateByIndex: [Int: Bool]
    private var resetAccessButtonWorkItem: DispatchWorkItem?

    // MARK: - Constants

    private enum AccessButton {
        static let id = "fullscreen.openAccess"
        static let iconConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
    }

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
        initialIndex: Int,
        playback: OnlinePlaybackCoordinating,
        accessActions: [Int: OnlineFullscreenAccessAction] = [:],
        onDismiss: @escaping (Int) -> Void
    ) {
        self.cameras = cameras
        self.playback = playback
        self.accessActions = accessActions
        self.onDismiss = onDismiss
        self.currentIndex = cameras.indices.contains(initialIndex) ? initialIndex : 0
        self.accessOpenedStateByIndex = accessActions.mapValues(\.isOpened)
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

        setupUI()
        setupConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Logger.logDebug("viewDidAppear")
        if view.bounds.width > view.bounds.height {
            logCameraLandscapeEnabled()
        }
        playback.setCloseHandler { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
        playback.setControlsAutoHideEnabled(true)
        playback.removeAllRightAccessoryItems()
        resetAccessButtonWorkItem?.cancel()

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

// MARK: - Private

private extension OnlineFullscreenViewController {
    func setupUI() {
        view.backgroundColor = .black
        configureAccessButton()
    }

    func setupConstraints() {
        view.pinSubview(collectionView)
    }

    func configureAccessButton() {
        guard let accessAction = accessAction(for: currentIndex) else {
            playback.setControlsAutoHideEnabled(true)
            playback.removeAllRightAccessoryItems()
            return
        }

        playback.setControlsAutoHideEnabled(false)
        playback.setRightAccessoryItems([
            accessButtonItem(
                isOpened: accessOpenedState(for: currentIndex),
                isEnabled: !accessOpenedState(for: currentIndex)
            )
        ])
    }

    func accessButtonItem(isOpened: Bool, isEnabled: Bool) -> SYPlayerControlAccessoryItem {
        SYPlayerControlAccessoryItem(
            id: AccessButton.id,
            image: accessButtonIcon(isOpened: false),
            selectedImage: accessButtonIcon(isOpened: true),
            disabledImage: accessButtonIcon(isOpened: isOpened),
            isEnabled: isEnabled,
            isSelected: isOpened,
            accessibilityLabel: isOpened ? L10n.Common.opened : L10n.Common.`open`,
            appearance: accessButtonAppearance(isOpened: isOpened),
            action: { [weak self] in
                self?.openButtonTapped()
            }
        )
    }

    func accessButtonIcon(isOpened: Bool) -> UIImage? {
        let symbolName = isOpened ? "lock.open.fill" : "lock.fill"
        return UIImage(systemName: symbolName, withConfiguration: AccessButton.iconConfiguration)?
            .withRenderingMode(.alwaysTemplate)
    }

    func accessButtonAppearance(isOpened: Bool) -> SYPlayerControlAccessoryAppearance {
        SYPlayerControlAccessoryAppearance(
            tintColor: .white,
            selectedTintColor: .white,
            disabledTintColor: .white,
            backgroundColor: .clear,
            selectedBackgroundColor: .clear,
            disabledBackgroundColor: .clear,
            borderColor: .clear,
            selectedBorderColor: .clear,
            disabledBorderColor: .clear,
            borderWidth: 0,
            cornerRadius: 8
        )
    }

    func openButtonTapped() {
        guard !isOpeningAccess,
              let accessAction = accessAction(for: currentIndex)
        else {
            return
        }

        isOpeningAccess = true
        let index = currentIndex
        updateAccessButton(index: index, isOpened: false, isEnabled: false)
        accessAction.open { [weak self] didOpen in
            DispatchQueue.main.async {
                guard let self else { return }

                self.isOpeningAccess = false
                guard didOpen else {
                    self.updateAccessButton(index: index, isOpened: false, isEnabled: true)
                    return
                }

                self.accessOpenedStateByIndex[index] = true
                self.updateAccessButton(index: index, isOpened: true, isEnabled: false)
                self.scheduleAccessButtonReset(index: index)
            }
        }
    }

    func updateAccessButton(index: Int, isOpened: Bool, isEnabled: Bool) {
        guard currentIndex == index else {
            return
        }

        playback.updateRightAccessoryItem(id: AccessButton.id) { item in
            item.image = self.accessButtonIcon(isOpened: false)
            item.selectedImage = self.accessButtonIcon(isOpened: true)
            item.disabledImage = self.accessButtonIcon(isOpened: isOpened)
            item.isEnabled = isEnabled
            item.isSelected = isOpened
            item.accessibilityLabel = isOpened ? L10n.Common.opened : L10n.Common.`open`
            item.appearance = self.accessButtonAppearance(isOpened: isOpened)
        }
    }

    func scheduleAccessButtonReset(index: Int) {
        resetAccessButtonWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.accessOpenedStateByIndex[index] = false
            self?.updateAccessButton(index: index, isOpened: false, isEnabled: true)
        }

        resetAccessButtonWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
    }

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
        configureAccessButton()

        let indexPath = IndexPath(item: index, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? OnlineFullscreenCameraCell {
            cell.resetZoomAndCenter()
            playback.willDisplay(cameraId: camera.id, cell: cell)
        }
    }

    func notifyDismiss() {
        guard !didNotifyDismiss else { return }
        didNotifyDismiss = true

        guard cameras.indices.contains(currentIndex) else { return }
        let cameraId = cameras[currentIndex].id
        Logger.logDebug("notifyDismiss id=\(cameraId) index=\(currentIndex)")
        logCameraFullscreenClosed()
        onDismiss(currentIndex)

        let indexPath = IndexPath(item: currentIndex, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? OnlineFullscreenCameraCell {
            playback.didEndDisplay(cameraId: cameraId, cell: cell)
        }
    }

    func setPagingHandoffActive(_ isActive: Bool) {
        guard isPagingHandoffActive != isActive else { return }
        isPagingHandoffActive = isActive

        guard !isActive else { return }
        updateCurrentIndexIfNeeded()
    }

    func accessAction(for index: Int) -> OnlineFullscreenAccessAction? {
        guard cameras.indices.contains(index) else {
            return nil
        }

        return accessActions[index]
    }

    var currentCameraId: CameraID? {
        guard cameras.indices.contains(currentIndex) else {
            return nil
        }

        return cameras[currentIndex].id
    }

    func accessOpenedState(for index: Int) -> Bool {
        guard cameras.indices.contains(index) else {
            return false
        }

        return accessOpenedStateByIndex[index] ?? accessActions[index]?.isOpened ?? false
    }

    func logCameraLandscapeEnabled() {
        AppAnalytics.log(
            AppAnalyticsEvent.cameraLandscapeEnabled(
                source: "fullscreen",
                cameraType: AnalyticsValue.unknown
            )
        )
    }

    func logCameraFullscreenClosed() {
        AppAnalytics.log(
            AppAnalyticsEvent.cameraFullscreenClosed(
                source: "fullscreen",
                cameraType: AnalyticsValue.unknown,
                streamType: "live"
            )
        )
    }
}
