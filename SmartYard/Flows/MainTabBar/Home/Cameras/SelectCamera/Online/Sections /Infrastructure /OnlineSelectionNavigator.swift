//
//  OnlineSelectionNavigator.swift
//  SmartYard
//
//  Created by Александр Попов on 28.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit

/// Отвечает только за UI-навигацию selection:
/// - scroll top carousel (section 0)
/// - scroll bottom carousel to page (section 1)
/// - select bottom item (section 1)
/// - programmatic gate для onTopCenteredIndex
final class OnlineSelectionNavigator {

    // MARK: - State

    private var didInitialScroll = false
    private var pendingIntent: OnlineSelectionIntent?

    private var isProgrammaticScroll = false
    private var targetIndex: Int?

    // MARK: - Public

    func onSectionsUpdated(
        _ sections: [OnlineSectionModel],
        collectionView: UICollectionView
    ) {
        tryApplyPending(in: collectionView)
    }

    func onCollectionLayout(_ collectionView: UICollectionView) {
        tryApplyPending(in: collectionView)
    }

    func apply(
        _ intent: OnlineSelectionIntent,
        in collectionView: UICollectionView
    ) {
        guard canApply(intent, in: collectionView) else {
            if pendingIntent != intent {
                Logger.logDebug(
                    "pending id=\(intent.cameraId) index=\(intent.index) source=\(intent.source.logValue)"
                )
            }
            pendingIntent = intent
            return
        }

        let shouldAnimate = didInitialScroll

        switch intent.source {
        case .preselected:
            let didScrollTop = scrollTopCarousel(
                collectionView,
                index: intent.index,
                animated: shouldAnimate,
                checkCentered: true,
                markProgrammatic: true
            )
            let didScrollBottom = scrollBottomCarouselToPage(
                collectionView,
                index: intent.index,
                animated: shouldAnimate
            )

            if (didScrollTop || didScrollBottom), collectionView.window != nil {
                didInitialScroll = true
            }
            selectBottomItem(collectionView, index: intent.index)

        case .mainCentered:
            let didScrollBottom = scrollBottomCarouselToPage(
                collectionView,
                index: intent.index,
                animated: shouldAnimate
            )
            if didScrollBottom, collectionView.window != nil {
                didInitialScroll = true
            }
            selectBottomItem(collectionView, index: intent.index)

        case .numberTap:
            let didScrollTop = scrollTopCarousel(
                collectionView,
                index: intent.index,
                animated: shouldAnimate,
                checkCentered: true,
                markProgrammatic: true
            )
            let didScrollBottom = scrollBottomCarouselToPage(
                collectionView,
                index: intent.index,
                animated: shouldAnimate
            )
            if (didScrollTop || didScrollBottom), collectionView.window != nil {
                didInitialScroll = true
            }
            selectBottomItem(collectionView, index: intent.index)
        }
    }

    /// Вызывается из layout builder (visibleItemsInvalidationHandler).
    /// Возвращает `true`, если нужно форвардить centered index в VM.
    func shouldForwardTopCenteredIndex(_ index: Int) -> Bool {
        guard isProgrammaticScroll else { return true }

        guard let targetIndex else {
            isProgrammaticScroll = false
            return false
        }

        if index == targetIndex {
            // Мы доехали до цели — на следующем centered можно снова пропускать.
            isProgrammaticScroll = false
            self.targetIndex = nil
        }

        return false
    }
}

// MARK: - Private

private extension OnlineSelectionNavigator {

    func canApply(
        _ intent: OnlineSelectionIntent,
        in collectionView: UICollectionView
    ) -> Bool {
        guard collectionView.bounds.width > 0, collectionView.bounds.height > 0 else { return false }
        // Нужны обе секции: 0 (камера) и 1 (номера/превью)
        guard collectionView.numberOfSections >= 2 else { return false }
        guard collectionView.numberOfItems(inSection: 0) > intent.index else { return false }
        guard collectionView.numberOfItems(inSection: 1) > intent.index else { return false }
        return true
    }

    func tryApplyPending(in collectionView: UICollectionView) {
        guard let pendingIntent else { return }
        // Если после обновления секций/лейаута мы уже можем применить — применяем.
        guard canApply(pendingIntent, in: collectionView) else { return }
        Logger.logDebug("applyPending id=\(pendingIntent.cameraId) index=\(pendingIntent.index)")
        self.pendingIntent = nil
        DispatchQueue.main.async { [weak self, weak collectionView] in
            guard let self, let collectionView else { return }
            self.apply(pendingIntent, in: collectionView)
        }
    }

    func setProgrammaticTarget(_ index: Int) {
        isProgrammaticScroll = true
        targetIndex = index
    }

    func currentTopCenteredIndex(
        _ collection: UICollectionView
    ) -> Int? {
        let visibleTop = collection.indexPathsForVisibleItems.filter { $0.section == 0 }
        guard let anyIndexPath = visibleTop.first,
              let attributes = collection.layoutAttributesForItem(at: anyIndexPath) else {
            return nil
        }

        let centerPoint = CGPoint(
            x: collection.contentOffset.x + collection.bounds.midX,
            y: attributes.frame.midY
        )

        guard let indexPath = collection.indexPathForItem(at: centerPoint),
              indexPath.section == 0 else {
            return nil
        }

        return indexPath.item
    }

    func scrollTopCarousel(
        _ collection: UICollectionView,
        index: Int,
        animated: Bool,
        checkCentered: Bool,
        markProgrammatic: Bool
    ) -> Bool {
        guard collection.numberOfSections > 0 else { return false }
        guard collection.numberOfItems(inSection: 0) > index else { return false }

        collection.layoutIfNeeded()

        if checkCentered, currentTopCenteredIndex(collection) == index {
            return false
        }

        if markProgrammatic {
            setProgrammaticTarget(index)
        }

        let topIndexPath = IndexPath(item: index, section: 0)
        collection.scrollToItem(at: topIndexPath, at: .centeredHorizontally, animated: animated)
        return true
    }

    func scrollBottomCarouselToPage(
        _ collection: UICollectionView,
        index: Int,
        animated: Bool
    ) -> Bool {
        guard collection.numberOfSections > 1 else { return false }

        let computedItemsPerPage = CameraNumberCarouselLayout.itemsPerPage(for: collection.bounds.size)
        let itemsPerPage = computedItemsPerPage > 1
            ? computedItemsPerPage
            : CameraNumberCarouselLayout.itemsPerPageFallback

        let page = index / itemsPerPage
        let targetItem = page * itemsPerPage
        guard collection.numberOfItems(inSection: 1) > targetItem else { return false }

        collection.layoutIfNeeded()
        let pageIndexPath = IndexPath(item: targetItem, section: 1)
        collection.scrollToItem(at: pageIndexPath, at: .centeredHorizontally, animated: animated)
        return true
    }

    func selectBottomItem(
        _ collection: UICollectionView,
        index: Int
    ) {
        guard collection.numberOfSections > 1 else { return }
        guard collection.numberOfItems(inSection: 1) > index else { return }

        collection.layoutIfNeeded()
        let exactIndexPath = IndexPath(item: index, section: 1)
        collection.selectItem(at: exactIndexPath, animated: false, scrollPosition: [])
    }
}
