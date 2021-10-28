//
//  SimpleButton.swift
//  SmartYard
//
//  Created by Александр Васильев on 27.10.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class SimpleButton: UIButton {
    
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
        titleLabel?.font = UIFont.SourceSansPro.semibold(size: 14)
        
        setTitleColor(UIColor.SmartYard.blue, for: .normal)
        
        setTitleColor(UIColor.SmartYard.blue.darken(by: 0.1), for: .highlighted)
        
        setTitleColor(.white, for: .disabled)
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        switch state {
        case .normal:
            backgroundColor = .white
            layerBorderWidth = 1
            layerBorderColor = UIColor.SmartYard.blue
            
        case .highlighted:
            backgroundColor = UIColor.white.darken(by: 0.1)
            layerBorderWidth = 1
            layerBorderColor = UIColor.SmartYard.blue.darken(by: 0.1)
            
        case .disabled:
            backgroundColor = UIColor.SmartYard.darkGreen
            layerBorderWidth = 0
            layerBorderColor = .clear
            
        default:
            break
        }
    }
}
