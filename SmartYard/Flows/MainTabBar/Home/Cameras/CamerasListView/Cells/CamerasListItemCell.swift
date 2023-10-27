//
//  CamerasListItem.swift
//  SmartYard
//
//  Created by Александр Васильев on 19.10.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit
import PinLayout

class CamerasListItemCell: UICollectionViewCell {
    
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
    
    private let mainContainer: UIView = {
        let view = UIView()
        
        view.backgroundColor = .clear
        
        return view
    }()
    
    private let rightImageView = UIImageView()
    var isHeader = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundColor = .white
        
        let titleDimensions = type(of: self).preferredHeight(
            for: bounds.width,
            title: titleLabel.text
        )
        
        let headerDimensions = type(of: self).preferredHeightForHeader(
            for: bounds.width,
            title: headerLabel.text
        )
        
        if isHeader {
            mainContainer.pin.all(type(of: self).mainContainerMargins)
        } else {
            mainContainer.pin.left(0).right(0).top(0).bottom(0)
        }
        
        rightImageView.pin
            .height(rightImageView.image?.size.height ?? type(of: self).arrowHeight)
            .width(rightImageView.image?.size.width ?? type(of: self).arrowWidth)
            .right()
            .vCenter()
        
        rightImageView.tintColor = UIColor(named: "gray")?.withAlphaComponent(0.5)
        
        if titleDimensions.titleLabelHeight != 0 {
            titleLabel.pin.top().marginLeft(16).bottom().width(titleDimensions.titleLabelWidth)
        }
        if headerDimensions.titleLabelHeight != 0 {
            headerLabel
                .pin
                .topLeft()
                .marginRight(0)
                .marginLeft(0)
                .width(headerDimensions.titleLabelWidth)
                .height(headerDimensions.titleLabelHeight)
        }
        
        layer.cornerRadius = 12
        layer.borderWidth = isHeader ? 1 : 0
        layer.borderColor = UIColor.SmartYard.grayBorder.cgColor
    }
    
    func configure(item: CamerasListItem) {
        contentView.removeSubviews()
        mainContainer.removeSubviews()
        
        addSubview(mainContainer)
        
        switch item {
        case .caption(label: let label):
            if !item.label.isEmpty {
                headerLabel.text = label
                mainContainer.addSubview(headerLabel)
            }
            isHeader = false
        case .camera:
            if !item.label.isEmpty {
                titleLabel.text = item.label
                mainContainer.addSubview(titleLabel)
            }
            rightImageView.image = UIImage(named: "PublicCamsMenuIcon")
            mainContainer.addSubview(rightImageView)
            isHeader = true
        case .group(label: let label, id: _, tree: _):
            if !item.label.isEmpty {
                titleLabel.text = label
                mainContainer.addSubview(titleLabel)
            }
            rightImageView.image = UIImage(named: "RightArrowIcon")
            mainContainer.addSubview(rightImageView)
            isHeader = true
        case .mapView(label: let label, id: _, cameras: _):
            if !item.label.isEmpty {
                titleLabel.text = label
                mainContainer.addSubview(titleLabel)
            }
            rightImageView.image = UIImage(named: "RightArrowIcon")
            mainContainer.addSubview(rightImageView)
            isHeader = true
         }
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
    
    class func preferredHeaderLabelHeight(for width: CGFloat, title: String?) -> CGFloat {
        guard !title.isNilOrEmpty else {
            return 0
        }
        
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
