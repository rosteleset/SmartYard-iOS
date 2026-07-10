//
//  OnlineFullscreenCameraCell.swift
//  SmartYard
//
//  Created by Александр Попов on 24.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit

final class OnlineFullscreenCameraCell: UICollectionViewCell, PlayerAttachable, PlayerControlsAttachable {
    let playerContainerView = UIView()
    let playerControlsContainerView: UIView = PlayerControlsOverlayView()

    private let zoomScrollView = EdgeHandoffZoomScrollView()
    private let minZoomScale: CGFloat = 1.0
    private let maxZoomScale: CGFloat = 5.0
    private var lastLayoutBoundsSize: CGSize = .zero

    var onPagingHandoffStateChanged: ((Bool) -> Void)? {
        get { zoomScrollView.onPagingHandoffStateChanged }
        set { zoomScrollView.onPagingHandoffStateChanged = newValue }
    }
    var onContentTap: (() -> Void)?

    var isZoomed: Bool {
        zoomScrollView.zoomScale > minZoomScale + 0.001
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetZoom()
    }

    override func layoutSubviews() {
        let previousBounds = zoomScrollView.bounds
        let previousContentSize = zoomScrollView.contentSize
        let previousContentOffset = zoomScrollView.contentOffset

        super.layoutSubviews()
        updateZoomLayout(
            previousBounds: previousBounds,
            previousContentSize: previousContentSize,
            previousContentOffset: previousContentOffset
        )
    }

    func resetZoom() {
        resetZoomAndCenter()
    }

    func resetZoomAndCenter() {
        zoomScrollView.setZoomScale(minZoomScale, animated: false)
        resetZoomContentToBounds()
        resetContentOffsetToCenter()
    }

    func setPagingPanGesture(_ panGesture: UIPanGestureRecognizer) {
        zoomScrollView.pagingScrollView = panGesture.view as? UIScrollView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleContentTap() {
        onContentTap?()
    }
}

private extension OnlineFullscreenCameraCell {
    func configureUI() {
        backgroundColor = .black
        contentView.backgroundColor = .black

        zoomScrollView.backgroundColor = .black
        zoomScrollView.minimumZoomScale = minZoomScale
        zoomScrollView.minimumContentZoomScale = minZoomScale
        zoomScrollView.maximumZoomScale = maxZoomScale
        zoomScrollView.bounces = false
        zoomScrollView.bouncesZoom = false
        zoomScrollView.showsHorizontalScrollIndicator = false
        zoomScrollView.showsVerticalScrollIndicator = false
        zoomScrollView.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleContentTap))
        tapGesture.cancelsTouchesInView = false
        zoomScrollView.addGestureRecognizer(tapGesture)

        playerContainerView.backgroundColor = .black
        playerControlsContainerView.backgroundColor = .clear
        contentView.addSubview(zoomScrollView)
        contentView.addSubview(playerControlsContainerView)
        zoomScrollView.addSubview(playerContainerView)

        zoomScrollView.frame = contentView.bounds
        zoomScrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerControlsContainerView.frame = contentView.bounds
        playerControlsContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerContainerView.frame = zoomScrollView.bounds
        playerContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func resetZoomContentToBounds() {
        let bounds = contentView.bounds
        guard bounds.size != .zero else { return }

        zoomScrollView.frame = bounds
        playerControlsContainerView.frame = bounds
        playerContainerView.transform = .identity
        playerContainerView.frame = CGRect(origin: .zero, size: bounds.size)
        zoomScrollView.contentSize = bounds.size
        lastLayoutBoundsSize = bounds.size
        applyCenteringInsets()
    }

    func resetContentOffsetToCenter() {
        zoomScrollView.contentOffset = clampedContentOffset(
            CGPoint(
                x: -zoomScrollView.contentInset.left,
                y: -zoomScrollView.contentInset.top
            )
        )
    }

    func applyCenteringInsets() {
        let boundsSize = zoomScrollView.bounds.size
        let contentFrame = playerContainerView.frame
        let verticalInset = max(0, (boundsSize.height - contentFrame.height) / 2)
        let horizontalInset = max(0, (boundsSize.width - contentFrame.width) / 2)
        zoomScrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }

    func updateZoomLayout(
        previousBounds: CGRect,
        previousContentSize: CGSize,
        previousContentOffset: CGPoint
    ) {
        let bounds = contentView.bounds
        guard bounds.size != .zero else { return }

        zoomScrollView.frame = bounds
        playerControlsContainerView.frame = bounds

        guard bounds.size != lastLayoutBoundsSize else {
            applyCenteringInsets()
            return
        }

        let previousZoomScale = zoomScrollView.zoomScale
        let normalizedCenter = normalizedVisibleCenter(
            bounds: previousBounds,
            contentSize: previousContentSize,
            contentOffset: previousContentOffset
        )

        lastLayoutBoundsSize = bounds.size
        zoomScrollView.setZoomScale(minZoomScale, animated: false)
        playerContainerView.transform = .identity
        playerContainerView.frame = CGRect(origin: .zero, size: bounds.size)
        zoomScrollView.contentSize = bounds.size

        let restoredZoomScale = min(max(previousZoomScale, minZoomScale), maxZoomScale)
        zoomScrollView.setZoomScale(restoredZoomScale, animated: false)
        applyCenteringInsets()
        restoreContentOffset(normalizedCenter: normalizedCenter)
    }

    func normalizedVisibleCenter(
        bounds: CGRect,
        contentSize: CGSize,
        contentOffset: CGPoint
    ) -> CGPoint {
        guard bounds.size != .zero, contentSize != .zero else {
            return CGPoint(x: 0.5, y: 0.5)
        }

        let visibleCenter = CGPoint(
            x: contentOffset.x + bounds.width / 2,
            y: contentOffset.y + bounds.height / 2
        )

        return CGPoint(
            x: min(1, max(0, visibleCenter.x / contentSize.width)),
            y: min(1, max(0, visibleCenter.y / contentSize.height))
        )
    }

    func restoreContentOffset(normalizedCenter: CGPoint) {
        let targetCenter = CGPoint(
            x: zoomScrollView.contentSize.width * normalizedCenter.x,
            y: zoomScrollView.contentSize.height * normalizedCenter.y
        )
        let targetOffset = CGPoint(
            x: targetCenter.x - zoomScrollView.bounds.width / 2,
            y: targetCenter.y - zoomScrollView.bounds.height / 2
        )

        zoomScrollView.contentOffset = clampedContentOffset(targetOffset)
    }

    func clampedContentOffset(_ offset: CGPoint) -> CGPoint {
        let inset = zoomScrollView.contentInset
        let minX = -inset.left
        let maxX = max(
            minX,
            zoomScrollView.contentSize.width - zoomScrollView.bounds.width + inset.right
        )
        let minY = -inset.top
        let maxY = max(
            minY,
            zoomScrollView.contentSize.height - zoomScrollView.bounds.height + inset.bottom
        )

        return CGPoint(
            x: min(maxX, max(minX, offset.x)),
            y: min(maxY, max(minY, offset.y))
        )
    }
}

extension OnlineFullscreenCameraCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        playerContainerView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        applyCenteringInsets()
    }
}
