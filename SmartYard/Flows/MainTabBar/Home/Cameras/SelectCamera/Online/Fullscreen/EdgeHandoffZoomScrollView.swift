//
//  EdgeHandoffZoomScrollView.swift
//  SmartYard
//
//  Created by Александр Попов on 12.05.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit

final class EdgeHandoffZoomScrollView: UIScrollView {
    var minimumContentZoomScale: CGFloat = 1.0
    weak var pagingScrollView: UIScrollView?
    var onPagingHandoffStateChanged: ((Bool) -> Void)?

    private let pagingHandoffActivationDistance: CGFloat = 44
    private var lastPanTranslationX: CGFloat = 0
    private var didHandoffPagingPan = false
    private var pagingHandoffDirection: CGFloat = 0
    private var pagingHandoffPullDistance: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture(_:)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === panGestureRecognizer else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }

        guard zoomScale > minimumContentZoomScale else { return false }

        let velocity = panGestureRecognizer.velocity(in: self)
        guard abs(velocity.x) > abs(velocity.y) else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }

        return shouldBeginHorizontalPan(velocity: velocity)
    }

    @objc private func handlePanGesture(_ panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
        case .began:
            lastPanTranslationX = panGesture.translation(in: self).x
            resetPagingHandoff()

        case .changed:
            let translationX = panGesture.translation(in: self).x
            let deltaX = translationX - lastPanTranslationX
            lastPanTranslationX = translationX
            handoffPagingPanIfNeeded(deltaX: deltaX)

        case .ended, .cancelled, .failed:
            finishPagingHandoff(velocityX: panGesture.velocity(in: self).x)
            lastPanTranslationX = 0
            resetPagingHandoff()

        default:
            break
        }
    }

    private func shouldBeginHorizontalPan(velocity: CGPoint) -> Bool {
        let minOffsetX = -adjustedContentInset.left
        let maxOffsetX = max(
            minOffsetX,
            contentSize.width - bounds.width + adjustedContentInset.right
        )

        let isAtLeftEdge = contentOffset.x <= minOffsetX + 0.5
        let isAtRightEdge = contentOffset.x >= maxOffsetX - 0.5

        if (isAtLeftEdge && velocity.x > 0) || (isAtRightEdge && velocity.x < 0) {
            return true
        }

        return true
    }

    private func handoffPagingPanIfNeeded(deltaX: CGFloat) {
        guard zoomScale > minimumContentZoomScale else { return }
        guard abs(deltaX) > .ulpOfOne else { return }
        guard let direction = pagingHandoffDirection(deltaX: deltaX), let pagingScrollView else {
            if !didHandoffPagingPan {
                pagingHandoffDirection = 0
                pagingHandoffPullDistance = 0
            }
            return
        }

        if pagingHandoffDirection != direction {
            pagingHandoffDirection = direction
            pagingHandoffPullDistance = 0
            didHandoffPagingPan = false
        }

        let effectiveDeltaX: CGFloat
        if didHandoffPagingPan {
            effectiveDeltaX = deltaX
        } else {
            pagingHandoffPullDistance += abs(deltaX)
            guard pagingHandoffPullDistance > pagingHandoffActivationDistance else { return }

            effectiveDeltaX = direction * (pagingHandoffPullDistance - pagingHandoffActivationDistance)
            didHandoffPagingPan = true
        }

        let minPagingOffsetX: CGFloat = 0
        let maxPagingOffsetX = max(
            minPagingOffsetX,
            pagingScrollView.contentSize.width - pagingScrollView.bounds.width
        )
        let nextPagingOffsetX = min(
            maxPagingOffsetX,
            max(minPagingOffsetX, pagingScrollView.contentOffset.x - effectiveDeltaX)
        )
        guard nextPagingOffsetX != pagingScrollView.contentOffset.x else { return }

        onPagingHandoffStateChanged?(true)
        pagingScrollView.setContentOffset(
            CGPoint(x: nextPagingOffsetX, y: pagingScrollView.contentOffset.y),
            animated: false
        )
    }

    private func pagingHandoffDirection(deltaX: CGFloat) -> CGFloat? {
        let minOffsetX = -adjustedContentInset.left
        let maxOffsetX = max(
            minOffsetX,
            contentSize.width - bounds.width + adjustedContentInset.right
        )

        let isAtLeftEdge = contentOffset.x <= minOffsetX + 0.5
        let isAtRightEdge = contentOffset.x >= maxOffsetX - 0.5
        if isAtLeftEdge && deltaX > 0 {
            return 1
        }
        if isAtRightEdge && deltaX < 0 {
            return -1
        }
        return nil
    }

    private func finishPagingHandoff(velocityX: CGFloat) {
        guard didHandoffPagingPan, let pagingScrollView else { return }
        guard pagingScrollView.bounds.width > 0 else { return }

        let pageWidth = pagingScrollView.bounds.width
        let rawPage = pagingScrollView.contentOffset.x / pageWidth
        let targetPage: CGFloat

        if abs(velocityX) > 500 {
            targetPage = velocityX > 0 ? floor(rawPage) : ceil(rawPage)
        } else {
            targetPage = round(rawPage)
        }

        let maxPage = max(0, floor((pagingScrollView.contentSize.width - pageWidth) / pageWidth))
        let clampedPage = min(maxPage, max(0, targetPage))
        let targetOffsetX = clampedPage * pageWidth

        pagingScrollView.setContentOffset(
            CGPoint(x: targetOffsetX, y: pagingScrollView.contentOffset.y),
            animated: true
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.onPagingHandoffStateChanged?(false)
        }
    }

    private func resetPagingHandoff() {
        didHandoffPagingPan = false
        pagingHandoffDirection = 0
        pagingHandoffPullDistance = 0
    }
}
