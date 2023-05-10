//
//  CameraLockButton.swift
//  SmartYard
//
//  Created by devcentra on 24.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit

class CameraLockButton: UIButton {
    
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
        layerCornerRadius = frame.width / 2
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        switch state {
        case .normal:
            backgroundColor = .clear
            layerBorderWidth = 2
            layerBorderColor = UIColor.SmartYard.blue
            tintColor = UIColor.SmartYard.blue
            
        case .highlighted:
            backgroundColor = .clear
            layerBorderWidth = 2
            layerBorderColor = UIColor.SmartYard.blue.lighten(by: 0.1)
            tintColor = UIColor.SmartYard.blue.lighten(by: 0.1)
            
        case .disabled:
            backgroundColor = UIColor.SmartYard.darkGreen
            layerBorderWidth = 0
            layerBorderColor = .clear
            tintColor = .white
            
        default:
            break
        }
    }
    
}

