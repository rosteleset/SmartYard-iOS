//
//  AddressesHeaderCell.swift
//  SmartYard
//
//  Created by admin on 17.07.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import PinLayout

final class AddressesHeaderCell: CustomBorderCollectionViewCell {
    
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundColor = .SmartYard.secondBackgroundColor
        
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
        
        arrowImageView.tintColor = UIColor.SmartYard.gray.withAlphaComponent(0.5)
        
        if dimensions.titleLabelHeight != 0 {
            titleLabel.pin.top().left().bottom().width(dimensions.titleLabelWidth)
        }
    }
    
    func configure(address: String?, isExpanded: Bool) {
        contentView.removeSubviews()
        mainContainer.removeSubviews()
        
        addSubview(mainContainer)
        
        titleLabel.text = address
        
        if !address.isNilOrEmpty {
            mainContainer.addSubview(titleLabel)
        }
        
        arrowImageView.image = isExpanded ?
            UIImage(named: "UpArrowIcon") :
            UIImage(named: "DownArrowIcon")
        
        mainContainer.addSubview(arrowImageView)
    }
    
}

extension AddressesHeaderCell {
    
    struct Dimensions {
        
        let totalHeight: CGFloat
        let titleLabelHeight: CGFloat
        let titleLabelWidth: CGFloat
        
    }
    
    static let minMainContainerHeight: CGFloat = 24
    static let mainContainerMargins: CGFloat = 24
    static let arrowWidth: CGFloat = 13
    static let arrowSpacing: CGFloat = 16
    static let arrowHeight: CGFloat = 8

    private static let heightCache = NSCache<NSString, NSNumber>()

    class func preferredTitleLabelHeight(for width: CGFloat, title: String?) -> CGFloat {
        guard let title = title, !title.isEmpty else { return 0 }

        let maxWidth = width - mainContainerMargins * 2 - arrowWidth - arrowSpacing
        let cacheKey = "\(width)_\(title)" as NSString

        if let cached = heightCache.object(forKey: cacheKey) {
            return CGFloat(truncating: cached)
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.SourceSansPro.regular(size: 14)
        ]
        let boundingRect = (title as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        let height = ceil(boundingRect.height)
        heightCache.setObject(NSNumber(value: Double(height)), forKey: cacheKey)
        return height
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
