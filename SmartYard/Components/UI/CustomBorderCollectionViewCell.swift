//
//  CustomBorderCollectionViewCell.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
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
    private let topLineMaskLayer = CALayer()
    private let bottomLineMaskLayer = CALayer()
    private let bottomLineSeparatorLayer = CALayer()
    
    private var separatorInset: CGFloat?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        borderLayer.frame = bounds
        
        topLineMaskLayer.frame = CGRect(
            x: topLineMaskLayer.frame.height,
            y: 0,
            width: bounds.width - 2 * topLineMaskLayer.frame.height,
            height: topLineMaskLayer.frame.height
        )
        
        guard let separatorInset = separatorInset else {
            return
        }
        
        bottomLineMaskLayer.frame = CGRect(
            x: bottomLineMaskLayer.frame.height,
            y: bounds.height - bottomLineMaskLayer.frame.height,
            width: bounds.width - 2 * bottomLineMaskLayer.frame.height,
            height: bottomLineMaskLayer.frame.height
        )
        
        bottomLineSeparatorLayer.frame = CGRect(
            x: bottomLineSeparatorLayer.frame.height + separatorInset,
            y: bounds.height - bottomLineSeparatorLayer.frame.height,
            width: bounds.width - 2 * (bottomLineSeparatorLayer.frame.height + separatorInset),
            height: bottomLineSeparatorLayer.frame.height
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
        customCornerRadius: CGFloat,
        separatorInset: CGFloat? = nil
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
            maskedCorners: maskedCorners,
            separatorInset: separatorInset
        )
    }
    
    private func addCustomBorder(
        customBorderWidth: CGFloat,
        customBorderColor: UIColor?,
        customCornerRadius: CGFloat,
        maskedCorners: CACornerMask,
        separatorInset: CGFloat?
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
        // Таким образом, избегаем двухпиксельного разделителя между ячейками
        
        if !maskedCorners.contains(.topCorners) {
            topLineMaskLayer.backgroundColor = backgroundColor?.cgColor
            
            topLineMaskLayer.frame = CGRect(
                x: customBorderWidth,
                y: 0,
                width: bounds.width - 2 * customBorderWidth,
                height: customBorderWidth
            )
            
            layer.addSublayer(topLineMaskLayer)
        }
        
        // MARK: Если ячейка не последняя в секции, и установлен separatorInset, то маскируем еще и нижнюю границу
        // Таким образом, устанавливаем кастомный отступ разделителя между ячейками
        
        if !maskedCorners.contains(.bottomCorners), let separatorInset = separatorInset {
            self.separatorInset = separatorInset
            
            bottomLineMaskLayer.backgroundColor = backgroundColor?.cgColor
            
            bottomLineMaskLayer.frame = CGRect(
                x: customBorderWidth,
                y: bounds.height - customBorderWidth,
                width: bounds.width - 2 * customBorderWidth,
                height: customBorderWidth
            )
            
            layer.addSublayer(bottomLineMaskLayer)
            
            bottomLineSeparatorLayer.backgroundColor = customBorderColor?.cgColor
            
            bottomLineSeparatorLayer.frame = CGRect(
                x: customBorderWidth + separatorInset,
                y: bounds.height - customBorderWidth,
                width: bounds.width - 2 * (customBorderWidth + separatorInset),
                height: customBorderWidth
            )
            
            layer.addSublayer(bottomLineSeparatorLayer)
        }
    }
    
    private func removeCustomBorder() {
        borderLayer.removeFromSuperlayer()
        topLineMaskLayer.removeFromSuperlayer()
        
        bottomLineMaskLayer.removeFromSuperlayer()
        bottomLineSeparatorLayer.removeFromSuperlayer()
        
        separatorInset = nil
    }
    
}
