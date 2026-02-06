//
//  SectionController.swift
//
//  Created by Александр Попов on 05.12.2025.
//

import UIKit

protocol SectionController {
  associatedtype Item

  // MARK: - Registration

  func registerCells(in collectionView: UICollectionView)

  // MARK: - Cell configuration

  func configureCell(
    at collectionView: UICollectionView,
    at indexPath: IndexPath,
    with item: Item
  ) -> UICollectionViewCell

  // MARK: - Selection

  func didSelect(item: Item, at indexPath: IndexPath)

  // MARK: - Display lifecyle

  func willDisplay(
    cell: UICollectionViewCell,
    at indexPath: IndexPath,
    item: Item
  )

  func didEndDisplaying(
    cell: UICollectionViewCell,
    at indexPath: IndexPath,
    item: Item
  )

  // MARK: - Highlight

  func didHighlight(item: Item, at indexPath: IndexPath)
  func didUnhighlight(item: Item, at indexPath: IndexPath)

  // MARK: - Prefetch

  func prefetch(items: [Item])
  func cancelPrefetching(items: [Item])
}

extension SectionController {
  func didSelect(item: Item, at indexPath: IndexPath) {}

  func willDisplay(
    cell: UICollectionViewCell,
    at indexPath: IndexPath,
    item: Item
  ) {}

  func didEndDisplaying(
    cell: UICollectionViewCell,
    at indexPath: IndexPath,
    item: Item
  ) {}

  func didHighlight(item: Item, at indexPath: IndexPath) {}
  func didUnhighlight(item: Item, at indexPath: IndexPath) {}

  func prefetch(items: [Item]) {}
  func cancelPrefetching(items: [Item]) {}
}
