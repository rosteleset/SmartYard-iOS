//
//  CameraNumberCarouselLayout.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit

struct CameraNumberCarouselLayout {
    static let itemSide: CGFloat = 36
    static let minHorizontalSpacing: CGFloat = 8
    static let minVerticalSpacing: CGFloat = 8
    static let extraHorizontalInset: CGFloat = 8
    static let topInset: CGFloat = 0
    static let bottomInset: CGFloat = 12
    static let itemsPerPageFallback = 30

    struct Metrics {
        let pageWidth: CGFloat
        let pageHeight: CGFloat
        let columns: Int
        let rows: Int
        let horizontalSpacing: CGFloat
        let verticalSpacing: CGFloat
        let topInset: CGFloat
        let bottomInset: CGFloat
        let sideInset: CGFloat

        var itemsPerPage: Int { columns * rows }
    }

    func make(with env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let metrics = Self.metrics(for: env.container.effectiveContentSize)

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(Self.itemSide),
            heightDimension: .absolute(Self.itemSide)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let rowSize = NSCollectionLayoutSize(
            widthDimension: .absolute(metrics.pageWidth),
            heightDimension: .absolute(Self.itemSide)
        )

        let rowGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: rowSize,
            subitem: item,
            count: metrics.columns
        )
        rowGroup.interItemSpacing = .fixed(metrics.horizontalSpacing)

        let pageSize = NSCollectionLayoutSize(
            widthDimension: .absolute(metrics.pageWidth),
            heightDimension: .absolute(metrics.pageHeight)
        )

        let pageGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: pageSize,
            subitem: rowGroup,
            count: metrics.rows
        )
        pageGroup.contentInsets = NSDirectionalEdgeInsets(
            top: metrics.topInset,
            leading: 0,
            bottom: metrics.bottomInset,
            trailing: 0
        )
        pageGroup.interItemSpacing = .fixed(metrics.verticalSpacing)

        let section = NSCollectionLayoutSection(group: pageGroup)
        section.interGroupSpacing = 16
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: metrics.sideInset,
            bottom: 0,
            trailing: metrics.sideInset
        )

        return section
    }
}

private extension CameraNumberCarouselLayout {
    static func metrics(for size: CGSize) -> Metrics {
        let containerWidth = size.width
        let basePageWidth = containerWidth * CameraCarouselLayout.groupWidth
        let extraInset = extraHorizontalInset
        let pageWidth = max(0, basePageWidth - extraInset * 2.0)
        let sideInset = containerWidth * ((1.0 - CameraCarouselLayout.groupWidth) / 2.0) + extraInset

        let cameraSectionHeight = basePageWidth * CameraCarouselLayout.ratio
            + CameraCarouselLayout.verticalInsets
        let pageHeight = max(0, size.height - cameraSectionHeight)
        let availableHeight = max(0, pageHeight - topInset - bottomInset)

        let columns = fitCount(
            length: pageWidth,
            item: itemSide,
            minSpacing: minHorizontalSpacing
        )
        let rows = fitCount(
            length: availableHeight,
            item: itemSide,
            minSpacing: minVerticalSpacing
        )

        let horizontalSpacing = spacingToFill(
            length: pageWidth,
            count: columns,
            item: itemSide
        )

        let verticalSpacing = minVerticalSpacing

        return Metrics(
            pageWidth: pageWidth,
            pageHeight: pageHeight,
            columns: columns,
            rows: rows,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            topInset: topInset,
            bottomInset: bottomInset,
            sideInset: sideInset
        )
    }

    static func fitCount(length: CGFloat, item: CGFloat, minSpacing: CGFloat) -> Int {
        guard length > 0 else { return 1 }
        let raw = floor((length + minSpacing) / (item + minSpacing))
        return max(1, Int(raw))
    }

    static func spacingToFill(length: CGFloat, count: Int, item: CGFloat) -> CGFloat {
        guard count > 1 else { return 0 }
        let totalItem = CGFloat(count) * item
        let gaps = CGFloat(count - 1)
        return max(0, (length - totalItem) / gaps)
    }
}

extension CameraNumberCarouselLayout {
    static func itemsPerPage(for size: CGSize) -> Int {
        let metrics = metrics(for: size)
        return max(1, metrics.itemsPerPage)
    }
}
