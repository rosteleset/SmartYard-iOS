//
//  SettingsHeaderCell.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import SnapKit

final class SettingsHeaderCell: CustomBorderCollectionViewCell {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.semibold(size: 18)
        label.textColor = UIColor.SmartYard.semiBlack
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.regular(size: 12)
        label.textColor = UIColor.SmartYard.gray
        return label
    }()

    private let mainContainer = UIView()
    private let centeringContainer = UIView()
    private let arrowImageView = UIImageView()

    func configure(title: String?, subtitle: String?, isExpanded: Bool) {
        contentView.removeSubviews()
        mainContainer.removeSubviews()
        centeringContainer.removeSubviews()

        backgroundColor = UIColor.SmartYard.secondBackgroundColor
        mainContainer.backgroundColor = .clear
        centeringContainer.backgroundColor = .clear

        let margins = type(of: self).mainContainerMargins

        pinSubview(mainContainer, with: .init(inset: margins))

        arrowImageView.image = isExpanded ?
            UIImage(named: "UpArrowIcon") :
            UIImage(named: "DownArrowIcon")
        arrowImageView.tintColor = UIColor.SmartYard.gray.withAlphaComponent(0.5)

        mainContainer.addSubview(arrowImageView) { make in
            make.height.equalTo(type(of: self).arrowHeight)
            make.width.equalTo(type(of: self).arrowWidth)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        mainContainer.addSubview(centeringContainer) { make in
            make.top.left.bottom.equalToSuperview()
            make.right.equalTo(arrowImageView.snp.left).offset(-type(of: self).arrowSpacing)
        }

        titleLabel.text = title
        subtitleLabel.text = subtitle

        let hasTitle = !title.isNilOrEmpty
        let hasSubtitle = !subtitle.isNilOrEmpty

        if hasTitle {
            centeringContainer.addSubview(titleLabel) { make in
                make.top.left.right.equalToSuperview()
                if !hasSubtitle {
                    make.bottom.equalToSuperview()
                }
            }
        }

        if hasSubtitle {
            centeringContainer.addSubview(subtitleLabel) { make in
                make.bottom.left.right.equalToSuperview()
                if hasTitle {
                    make.top.equalTo(titleLabel.snp.bottom).offset(type(of: self).labelSpacing)
                } else {
                    make.top.equalToSuperview()
                }
            }
        }
    }
    
}

extension SettingsHeaderCell {
    
    struct Dimensions {
        let totalHeight: CGFloat
        let mainContainerHeight: CGFloat
        let centeringContainerWidth: CGFloat
        let titleLabelHeight: CGFloat
        let subtitleLabelHeight: CGFloat
    }
    
    static let mainContainerMargins: CGFloat = 24
    static let arrowWidth: CGFloat = 13
    static let arrowSpacing: CGFloat = 16
    static let arrowHeight: CGFloat = 8
    static let labelSpacing: CGFloat = 10
    
    class func preferredTitleLabelHeight(for width: CGFloat, title: String?) -> CGFloat {
        guard !title.isNilOrEmpty else { return 0 }

        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.semibold(size: 18)
        label.text = title
        

        return label.sizeThatFits(
            CGSize(
                width: width - mainContainerMargins * 2 - arrowWidth - arrowSpacing,
                height: 1000
            )
        ).height
    }

    class func preferredSubtitleLabelHeight(for width: CGFloat, subtitle: String?) -> CGFloat {
        guard !subtitle.isNilOrEmpty else { return 0 }

        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.regular(size: 12)
        label.text = subtitle

        return label.sizeThatFits(
            CGSize(
                width: width - mainContainerMargins * 2 - arrowWidth - arrowSpacing,
                height: 1000
            )
        ).height
    }

    class func preferredHeight(for width: CGFloat, title: String?, subtitle: String?) -> Dimensions {
        let titleLabelHeight = preferredTitleLabelHeight(for: width, title: title)
        let subtitleLabelHeight = preferredSubtitleLabelHeight(for: width, subtitle: subtitle)
        let nonZeroHeightLabels = [titleLabelHeight, subtitleLabelHeight].filter { $0 != 0 }
        let labelsSummaryHeight = nonZeroHeightLabels.reduce(0, +)
        let interitemSpacings = CGFloat(max((nonZeroHeightLabels.count - 1), 0)) * labelSpacing
        let mainContainerHeight = max(arrowHeight, labelsSummaryHeight + interitemSpacings)
        let totalHeight = mainContainerMargins * 2 + mainContainerHeight

        return Dimensions(
            totalHeight: totalHeight,
            mainContainerHeight: mainContainerHeight,
            centeringContainerWidth: width - mainContainerMargins * 2 - arrowWidth - arrowSpacing,
            titleLabelHeight: titleLabelHeight,
            subtitleLabelHeight: subtitleLabelHeight
        )
    }
}
