//
//  OnlineFullscreenCameraCell.swift
//  SmartYard
//
//  Created by Александр Попов on 24.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit

final class OnlineFullscreenCameraCell: UICollectionViewCell, PlayerAttachable {
    let playerContainerView = UIView()

    private let zoomScrollView = UIScrollView()
    private let minZoomScale: CGFloat = 1.0
    private let maxZoomScale: CGFloat = 5.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetZoom()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyCenteringInsets()
    }

    func resetZoom() {
        guard zoomScrollView.zoomScale != minZoomScale else {
            applyCenteringInsets()
            return
        }

        zoomScrollView.setZoomScale(minZoomScale, animated: false)
        applyCenteringInsets()
    }

    func setPagingPanGesture(_ panGesture: UIPanGestureRecognizer) {
        zoomScrollView.panGestureRecognizer.require(toFail: panGesture)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension OnlineFullscreenCameraCell {
    func configureUI() {
        backgroundColor = .black
        contentView.backgroundColor = .black

        zoomScrollView.backgroundColor = .black
        zoomScrollView.minimumZoomScale = minZoomScale
        zoomScrollView.maximumZoomScale = maxZoomScale
        zoomScrollView.bouncesZoom = false
        zoomScrollView.showsHorizontalScrollIndicator = false
        zoomScrollView.showsVerticalScrollIndicator = false
        zoomScrollView.delegate = self

        playerContainerView.backgroundColor = .black
        contentView.addSubview(zoomScrollView)
        zoomScrollView.addSubview(playerContainerView)

        zoomScrollView.frame = contentView.bounds
        zoomScrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerContainerView.frame = zoomScrollView.bounds
        playerContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
}

extension OnlineFullscreenCameraCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        playerContainerView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        applyCenteringInsets()
    }
}
