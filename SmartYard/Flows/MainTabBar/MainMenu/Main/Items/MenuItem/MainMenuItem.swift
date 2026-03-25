//
//  MainMenuItemCollectionViewCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 06.01.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import SnapKit

final class MainMenuItem: UICollectionViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.regular(size: 14)
        label.textColor = UIColor.SmartYard.semiBlack
        return label
    }()

    private let mainContainer = UIView()
    private let arrowImageView = UIImageView()
    private let iconImageView = UIImageView()

    func configure(name: String?, iconName: String? = nil, icon: UIImage? = nil) {
        contentView.removeSubviews()
        mainContainer.removeSubviews()

        backgroundColor = .SmartYard.secondBackgroundColor
        mainContainer.backgroundColor = .clear

        let margins = type(of: self).mainContainerMargins

        pinSubview(mainContainer, with: .init(inset: margins))

        titleLabel.text = name

        if icon != nil {
            iconImageView.image = icon?.withRenderingMode(.alwaysTemplate)
        } else {
            iconImageView.image = UIImage(named: iconName ?? "PublicCamsMenuIcon")
        }
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor.SmartYard.gray

        mainContainer.addSubview(iconImageView) { make in
            make.height.width.equalTo(24)
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        arrowImageView.image = UIImage(named: "RightArrowIcon")
        arrowImageView.tintColor = UIColor.SmartYard.gray.withAlphaComponent(0.5)

        mainContainer.addSubview(arrowImageView) { make in
            make.height.equalTo(type(of: self).arrowHeight)
            make.width.equalTo(type(of: self).arrowWidth)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        if !name.isNilOrEmpty {
            mainContainer.addSubview(titleLabel) { make in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(iconImageView.snp.right).offset(16)
                make.right.equalTo(arrowImageView.snp.left).offset(-type(of: self).arrowSpacing)
            }
        }

        layer.cornerRadius = 12
        addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
    }
}

extension MainMenuItem {
    
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
}
