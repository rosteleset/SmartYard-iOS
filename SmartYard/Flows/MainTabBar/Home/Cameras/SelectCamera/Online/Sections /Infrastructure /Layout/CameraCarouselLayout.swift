//
//  CameraCarouselLayout.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit

struct CameraCarouselLayout {

    static let ratio: CGFloat = 9.0 / 16.0
    static let groupWidth: CGFloat = 0.85
    static let topInset: CGFloat = 12
    static let bottomInset: CGFloat = 12
    static let verticalInsets: CGFloat = topInset + bottomInset

    func make(
        with env: NSCollectionLayoutEnvironment,
        onCenteredIndex: ((Int) -> Void)? = nil
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(Self.groupWidth),
            heightDimension: .fractionalWidth(Self.groupWidth * Self.ratio)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let containerWidth = env.container.effectiveContentSize.width
        let sideInset = containerWidth * ((1.0 - Self.groupWidth) / 2.0)

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.interGroupSpacing = 16
        section.contentInsets = .init(
            top: Self.topInset,
            leading: sideInset,
            bottom: Self.bottomInset,
            trailing: sideInset
        )
        if let onCenteredIndex {
            section.visibleItemsInvalidationHandler = { items, offset, environment in
                let containerCenterX = offset.x + environment.container.effectiveContentSize.width / 2.0
                let visibleCells = items.filter { $0.representedElementCategory == .cell }
                guard let closest = visibleCells.min(by: {
                    abs($0.center.x - containerCenterX) < abs($1.center.x - containerCenterX)
                }) else { return }
                onCenteredIndex(closest.indexPath.item)
            }
        }

        return section
    }
}
