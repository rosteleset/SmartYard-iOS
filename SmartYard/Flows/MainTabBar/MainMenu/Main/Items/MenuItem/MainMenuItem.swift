//
//  MainMenuItemCollectionViewCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 06.01.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import PinLayout

class MainMenuItem: UICollectionViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        
        label.numberOfLines = 0
        label.font = UIFont.SourceSansPro.regular(size: 14)
        label.textColor = UIColor.SmartYard.semiBlack
        
        return label
    }()
    
    private let mainContainer: UIView = {
        let view = UIView()
        
        view.backgroundColor = .clear
        
        return view
    }()
    
    private let arrowImageView = UIImageView()
    private let iconImageView = UIImageView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundColor = .white
        
        let dimensions = type(of: self).preferredHeight(
            for: bounds.width,
            title: titleLabel.text
        )
        
        mainContainer.pin.all(type(of: self).mainContainerMargins)
        
        arrowImageView.pin
            .height(type(of: self).arrowHeight)
            .width(type(of: self).arrowWidth)
            .right()
            .vCenter()
        
        iconImageView.pin
            .height(24)
            .width(24)
            .left()
            .vCenter()
        
        arrowImageView.tintColor = UIColor(hex: 0x6D7A8A)?.withAlphaComponent(0.5)
        
        if dimensions.titleLabelHeight != 0 {
            titleLabel.pin.top().right(of: iconImageView).marginLeft(16).bottom().width(dimensions.titleLabelWidth)
        }
        
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.SmartYard.grayBorder.cgColor
    }
    
    func configure(name: String?, iconName: String? = nil, icon: UIImage? = nil) {
        contentView.removeSubviews()
        mainContainer.removeSubviews()
        
        addSubview(mainContainer)
        
        titleLabel.text = name
        
        if !name.isNilOrEmpty {
            mainContainer.addSubview(titleLabel)
        }
        
        arrowImageView.image = UIImage(named: "RightArrowIcon")
        
        if icon != nil {
            iconImageView.image = icon?.withRenderingMode(.alwaysTemplate)
        } else {
            iconImageView.image = UIImage(named: iconName ?? "PublicCamsMenuIcon")
        }
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor.SmartYard.gray
        
        mainContainer.addSubview(iconImageView)
        mainContainer.addSubview(arrowImageView)
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
        guard !title.isNilOrEmpty else {
            return 0
        }
        
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
