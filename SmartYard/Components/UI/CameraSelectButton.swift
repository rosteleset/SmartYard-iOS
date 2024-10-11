//
//  CameraSelectButton.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 14.03.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit

class CameraSelectButton: UIButton {
    
    override var isHighlighted: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareUI()
    }
    
    private func prepareUI() {
        layerCornerRadius = 8
        titleLabel?.font = UIFont.SourceSansPro.regular(size: 14)
        
        setTitleColor(.white, for: .normal)
        setTitleColor(.white, for: .highlighted)
        setTitleColor(.darkGray, for: .disabled)
        layerBorderWidth = 0

        updateAppearance()
    }
    
    private func updateAppearance() {
        switch state {
        case .normal:
            backgroundColor = UIColor.lightGray
            
        case .highlighted:
            backgroundColor = UIColor.SmartYard.blue
            
        case .disabled:
            backgroundColor = UIColor.lightGray
            
        default:
            break
        }
    }
}
