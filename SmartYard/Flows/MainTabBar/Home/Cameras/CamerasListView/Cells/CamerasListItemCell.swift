//
//  CamerasListItem.swift
//  SmartYard
//
//  Created by Александр Васильев on 19.10.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit
import SnapKit

final class CamerasListItemCell: UICollectionViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.regular(size: 14)
        label.textColor = UIColor.SmartYard.semiBlack
        return label
    }()

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.bold(size: 24)
        label.textColor = UIColor.SmartYard.semiBlack
        return label
    }()

    private let mainContainer = UIView()
    private let rightImageView = UIImageView()

    var isHeader = false

    private func addRightImageView(image: UIImage?) {
        rightImageView.image = image
        rightImageView.tintColor = UIColor.SmartYard.gray.withAlphaComponent(0.5)
        mainContainer.addSubview(rightImageView) { make in
            make.height.equalTo(image?.size.height ?? type(of: self).arrowHeight)
            make.width.equalTo(image?.size.width ?? type(of: self).arrowWidth)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    private func addTitleLabel(text: String) {
        titleLabel.text = text
        mainContainer.addSubview(titleLabel) { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(rightImageView.snp.left).offset(-type(of: self).arrowSpacing)
        }
    }

    func configure(item: CamerasListItem) {
        contentView.removeSubviews()
        mainContainer.removeSubviews()

        backgroundColor = .SmartYard.secondBackgroundColor
        mainContainer.backgroundColor = .clear

        switch item {
        case .caption(label: let label):
            isHeader = false
            if !item.label.isEmpty {
                headerLabel.text = label
                mainContainer.addSubview(headerLabel) { make in
                    make.top.left.equalToSuperview()
                    make.width.equalToSuperview()
                }
            }
        case .camera:
            isHeader = true
            addRightImageView(image: UIImage(named: "PublicCamsMenuIcon"))
            if !item.label.isEmpty {
                addTitleLabel(text: item.label)
            }
        case .group(label: let label, id: _, tree: _):
            isHeader = true
            addRightImageView(image: UIImage(named: "RightArrowIcon"))
            if !item.label.isEmpty {
                addTitleLabel(text: label)
            }
        case .mapView(label: let label, id: _, cameras: _):
            isHeader = true
            addRightImageView(image: UIImage(named: "RightArrowIcon"))
            if !item.label.isEmpty {
                addTitleLabel(text: label)
            }
        }

        let margins = type(of: self).mainContainerMargins
        let insets: UIEdgeInsets = isHeader ? .init(inset: margins) : .zero
        pinSubview(mainContainer, with: insets)

        layer.cornerRadius = 12
        layer.borderWidth = isHeader ? 1 : 0
        addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
    }
}

extension CamerasListItemCell {

    struct Dimensions {
        let totalHeight: CGFloat
        let titleLabelHeight: CGFloat
        let titleLabelWidth: CGFloat
    }

    static let minMainContainerHeight: CGFloat = 24
    static let mainContainerMargins: CGFloat = 24
    static let arrowWidth: CGFloat = 8
    static let arrowSpacing: CGFloat = 16
    static let arrowHeight: CGFloat = 13

    class func preferredTitleLabelHeight(for width: CGFloat, title: String?) -> CGFloat {
        guard !title.isNilOrEmpty else { return 0 }

        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.regular(size: 14)
        label.text = title

        return label.sizeThatFits(
            CGSize(width: width - mainContainerMargins * 2 - arrowWidth - arrowSpacing, height: 1000)
        ).height
    }

    class func preferredHeaderLabelHeight(for width: CGFloat, title: String?) -> CGFloat {
        guard !title.isNilOrEmpty else { return 0 }

        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.bold(size: 24)
        label.text = title

        return label.sizeThatFits(
            CGSize(width: width - mainContainerMargins * 2, height: 1000)
        ).height
    }

    class func preferredHeight(for width: CGFloat, title: String?) -> Dimensions {
        let titleLabelHeight = preferredTitleLabelHeight(for: width, title: title)
        let mainContainerHeight = max(arrowHeight, titleLabelHeight, minMainContainerHeight)
        let totalHeight = mainContainerMargins * 2 + mainContainerHeight
        let titleLabelWidth = width - mainContainerMargins * 2 - arrowWidth - arrowSpacing

        return Dimensions(
            totalHeight: totalHeight,
            titleLabelHeight: titleLabelHeight,
            titleLabelWidth: titleLabelWidth
        )
    }

    class func preferredHeightForHeader(for width: CGFloat, title: String?) -> Dimensions {
        let titleLabelHeight = preferredHeaderLabelHeight(for: width, title: title)
        let mainContainerHeight = max(arrowHeight, titleLabelHeight, minMainContainerHeight)
        let totalHeight = mainContainerHeight
        let titleLabelWidth = width

        return Dimensions(
            totalHeight: totalHeight,
            titleLabelHeight: titleLabelHeight,
            titleLabelWidth: titleLabelWidth
        )
    }
}
