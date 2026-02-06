//
//  AnySectionController.swift
//
//  Created by Александр Попов on 05.12.2025.
//

import UIKit

final class AnySectionController<ScreenItem> {
  private let _registerCells: (UICollectionView) -> Void

  private let _configureCell: (
    UICollectionView,
    IndexPath,
    ScreenItem
  ) -> UICollectionViewCell

  private let _didSelect: (ScreenItem, IndexPath) -> Void

  private let _willDisplay: (
    UICollectionViewCell,
    IndexPath,
    ScreenItem
  ) -> Void

  private let _didEndDisplaying: (
    UICollectionViewCell,
    IndexPath,
    ScreenItem
  ) -> Void

  private let _didHighlight: (ScreenItem, IndexPath) -> Void
  private let _didUnhighlight: (ScreenItem, IndexPath) -> Void

  private let _prefetch: ([ScreenItem]) -> Void
  private let _cancelPrefetch: ([ScreenItem]) -> Void

  init<SC: SectionController>(
    _ controller: SC,
    mapItem: @escaping (ScreenItem) -> SC.Item?
  ) {
    _registerCells = { collectionView in
      controller.registerCells(in: collectionView)
    }

    _configureCell = { collectionView, indexPath, screenItem in
      guard let item = mapItem(screenItem) else {
        assertionFailure("Wrong ScreenItem for this SectionController")
        return UICollectionViewCell()
      }

      return controller.configureCell(
        at: collectionView,
        at: indexPath,
        with: item
      )
    }

    _didSelect = { screenItem, indexPath in
      guard let item = mapItem(screenItem) else { return }
      controller.didSelect(item: item, at: indexPath)
    }

    _willDisplay = { cell, indexPath, screenItem in
      guard let item = mapItem(screenItem) else { return }
      controller.willDisplay(cell: cell, at: indexPath, item: item)
    }

    _didEndDisplaying = { cell, indexPath, screenItem in
      guard let item = mapItem(screenItem) else { return }
      controller.didEndDisplaying(cell: cell, at: indexPath, item: item)
    }

    _didHighlight = { screenItem, indexPath in
      guard let item = mapItem(screenItem) else { return }
      controller.didHighlight(item: item, at: indexPath)
    }

    _didUnhighlight = { screenItem, indexPath in
      guard let item = mapItem(screenItem) else { return }
      controller.didUnhighlight(item: item, at: indexPath)
    }

    _prefetch = { screenItems in
      let items = screenItems.compactMap(mapItem)
      controller.prefetch(items: items)
    }

    _cancelPrefetch = { screenItems in
      let items = screenItems.compactMap(mapItem)
      controller.cancelPrefetching(items: items)
    }
  }

  // MARK: - Public methods

  func registerCells(in collectionView: UICollectionView) {
    _registerCells(collectionView)
  }

  func configureCell(
    in collectionView: UICollectionView,
    at indexPath: IndexPath,
    with screenItem: ScreenItem
  ) -> UICollectionViewCell {
    _configureCell(collectionView, indexPath, screenItem)
  }

  func didSelect(screenItem: ScreenItem, at indexPath: IndexPath) {
    _didSelect(screenItem, indexPath)
  }

  func willDisplay(
    _ cell: UICollectionViewCell,
    at indexPath: IndexPath,
    for screenItem: ScreenItem
  ) {
    _willDisplay(cell, indexPath, screenItem)
  }

  func didEndDisplay(
    _ cell: UICollectionViewCell,
    at indexPath: IndexPath,
    for screenItem: ScreenItem
  ) {
    _didEndDisplaying(cell, indexPath, screenItem)
  }

  func didHighlight(screenItem: ScreenItem, at indexPath: IndexPath) {
    _didHighlight(screenItem, indexPath)
  }

  func didUnhighlight(screenItem: ScreenItem, at indexPath: IndexPath) {
    _didUnhighlight(screenItem, indexPath)
  }

  func prefetch(screenItems: [ScreenItem]) {
    _prefetch(screenItems)
  }

  func cancelPrefetch(screenItems: [ScreenItem]) {
    _cancelPrefetch(screenItems)
  }
}
