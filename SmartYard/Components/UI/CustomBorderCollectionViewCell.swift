//
//  CustomBorderCollectionViewCell.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class CustomBorderCollectionViewCell: UICollectionViewCell {
    
    private let borderLayer = CALayer()
    private let bottomLineLayer = CALayer()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        borderLayer.frame = bounds
        
        bottomLineLayer.frame = CGRect(
            x: bottomLineLayer.frame.height,
            y: bounds.height - bottomLineLayer.frame.height,
            width: bounds.width - 2 * bottomLineLayer.frame.height,
            height: bottomLineLayer.frame.height
        )
    }
    
    func addCustomBorder(
        isFirstInSection: Bool,
        isLastInSection: Bool,
        customBorderWidth: CGFloat,
        customBorderColor: UIColor?,
        customCornerRadius: CGFloat
    ) {
        var maskedCorners = CACornerMask()
        
        if isFirstInSection {
            maskedCorners.insert([.layerMinXMinYCorner, .layerMaxXMinYCorner])
        }
        
        if isLastInSection {
            maskedCorners.insert([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
        }
        
        addCustomBorder(
            customBorderWidth: 1,
            customBorderColor: UIColor(hex: 0xF0F0F1),
            customCornerRadius: 12,
            maskedCorners: maskedCorners
        )
    }
    
    private func addCustomBorder(
        customBorderWidth: CGFloat,
        customBorderColor: UIColor?,
        customCornerRadius: CGFloat,
        maskedCorners: CACornerMask
    ) {
        removeCustomBorder()
        
        borderLayer.borderWidth = customBorderWidth
        borderLayer.borderColor = customBorderColor?.cgColor
        borderLayer.frame = bounds
        layer.addSublayer(borderLayer)
        
        layer.cornerRadius = customCornerRadius
        layer.maskedCorners = maskedCorners
        
        borderLayer.cornerRadius = customCornerRadius
        borderLayer.maskedCorners = maskedCorners
        
        guard !maskedCorners.contains([.layerMinXMaxYCorner, .layerMaxXMaxYCorner]) else {
            return
        }
        
        bottomLineLayer.backgroundColor = backgroundColor?.cgColor
        
        bottomLineLayer.frame = CGRect(
            x: customBorderWidth,
            y: bounds.height - customBorderWidth,
            width: bounds.width - 2 * customBorderWidth,
            height: customBorderWidth
        )
        
        layer.addSublayer(bottomLineLayer)
    }
    
    private func removeCustomBorder() {
        borderLayer.removeFromSuperlayer()
        bottomLineLayer.removeFromSuperlayer()
    }
    
}
