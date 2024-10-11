//
//  SettingsHeaderCell.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import PinLayout

class SettingsHeaderCell: CustomBorderCollectionViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.semibold(size: 18)
        label.textColor = UIColor.SmartYard.textAddon
        
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.regular(size: 12)
        label.textColor = UIColor.SmartYard.gray
        
        return label
    }()
    
    private let mainContainer: UIView = {
        let view = UIView()
        
        view.backgroundColor = .clear
        
        return view
    }()
    
    private let centeringContainer: UIView = {
        let view = UIView()
        
        view.backgroundColor = .clear
        
        return view
    }()
    
    private let arrowImageView = UIImageView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundColor = .white
        
        let dimensions = type(of: self).preferredHeight(
            for: bounds.width,
            title: titleLabel.text,
            subtitle: subtitleLabel.text
        )
        
        mainContainer.pin.all(type(of: self).mainContainerMargins)
        
        arrowImageView.pin
            .height(type(of: self).arrowHeight)
            .width(type(of: self).arrowWidth)
            .right()
            .vCenter()
        
        arrowImageView.tintColor = UIColor(hex: 0x6D7A8A)?.withAlphaComponent(0.5)
        
        centeringContainer.pin.top().left().bottom().width(dimensions.centeringContainerWidth)
        
        if dimensions.titleLabelHeight != 0 {
            titleLabel.pin.top().left().right().height(dimensions.titleLabelHeight)
        }
        
        if dimensions.subtitleLabelHeight != 0 {
            subtitleLabel.pin.bottom().left().right().height(dimensions.subtitleLabelHeight)
        }
    }
    
    func configure(title: String?, subtitle: String?, isExpanded: Bool) {
        contentView.removeSubviews()
        mainContainer.removeSubviews()
        centeringContainer.removeSubviews()
        
        addSubview(mainContainer)
        mainContainer.addSubview(centeringContainer)
        
        titleLabel.text = title
        subtitleLabel.text = subtitle
        
        if !title.isNilOrEmpty {
            centeringContainer.addSubview(titleLabel)
        }
        
        if !subtitle.isNilOrEmpty {
            centeringContainer.addSubview(subtitleLabel)
        }
        
        arrowImageView.image = isExpanded ?
            UIImage(named: "UpArrowIcon") :
            UIImage(named: "DownArrowIcon")
        
        mainContainer.addSubview(arrowImageView)
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
        guard !title.isNilOrEmpty else {
            return 0
        }
        
        let label = UILabel()
        
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.semibold(size: 18)
        label.text = title
        
        return label.sizeThatFits(
            CGSize(width: width - mainContainerMargins * 2 - arrowWidth - arrowSpacing, height: 1000)
        ).height
    }
    
    class func preferredSubtitleLabelHeight(for width: CGFloat, subtitle: String?) -> CGFloat {
        guard !subtitle.isNilOrEmpty else {
            return 0
        }
        
        let label = UILabel()
        
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.regular(size: 12)
        label.text = subtitle
        
        return label.sizeThatFits(
            CGSize(width: width - mainContainerMargins * 2 - arrowWidth - arrowSpacing, height: 1000)
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
