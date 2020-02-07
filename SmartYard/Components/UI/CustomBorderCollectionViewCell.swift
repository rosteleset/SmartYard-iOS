//
//  CustomBorderCollectionViewCell.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

// MARK: В общем, надо было сделать вокруг всей секции бордер, и между ячейками тоже разделитель
// Сначала я просто добавил бордер однопиксельный вокруг каждой ячейки
// И все было бы окей, но в местах, где ячейки соприкасались друг с другом, разделитель получался два пикселя
// Поскольку мне было лень делать кастомный лайаут для CollectionView, я решил добавить качественный костыль
// Добавил отдельный Layer для бордера, а поверх него добавил еще один, который перекрывает бордер
// По толщине он равен толщине бордера, по цвету совпадает с бэкграундом ячейки
// Получается, что он как бы маскирует бордер под собой и делает вид, что его "типа там нет"

class CustomBorderCollectionViewCell: UICollectionViewCell {
    
    private let borderLayer = CALayer()
    private let bottomLineLayer = CALayer()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        borderLayer.frame = bounds
        
        bottomLineLayer.frame = CGRect(
            x: bottomLineLayer.frame.height,
            y: 0,
            width: bounds.width - 2 * bottomLineLayer.frame.height,
            height: bottomLineLayer.frame.height
        )
    }
    
    // MARK: Если ячейка первая в секции, то мы закругляем верхние углы
    // Если ячейка последняя в секции, то мы закругляем нижние углы
    // Если ячейка не первая в секции, то нам нужно замаскировать верхнюю границу, чтобы разделитель был в 1 пиксель
    func addCustomBorder(
        isFirstInSection: Bool,
        isLastInSection: Bool,
        customBorderWidth: CGFloat,
        customBorderColor: UIColor?,
        customCornerRadius: CGFloat
    ) {
        var maskedCorners = CACornerMask()
        
        if isFirstInSection {
            maskedCorners.insert(.topCorners)
        }
        
        if isLastInSection {
            maskedCorners.insert(.bottomCorners)
        }
        
        addCustomBorder(
            customBorderWidth: customBorderWidth,
            customBorderColor: customBorderColor,
            customCornerRadius: customCornerRadius,
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
        
        // MARK: Если ячейка не первая в секции, то маскируем верхнюю границу
        guard !maskedCorners.contains(.topCorners) else {
            return
        }
        
        bottomLineLayer.backgroundColor = backgroundColor?.cgColor
        
        bottomLineLayer.frame = CGRect(
            x: customBorderWidth,
            y: 0,
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
