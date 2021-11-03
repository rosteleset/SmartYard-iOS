//
//  WhiteButtonWithBorder.swift
//  SmartYard
//
//  Created by Mad Brains on 07.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

class WhiteButtonWithBorder: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layerCornerRadius = 12
        backgroundColor = .white
        layerBorderWidth = 1
        updateAppearance()
    }
    
    override var isEnabled: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    private func updateAppearance() {
        switch state {
        case .normal:
            layerBorderColor = UIColor.SmartYard.blue
            titleLabel?.textColor = UIColor.SmartYard.blue
        case .disabled:
            layerBorderColor = UIColor.SmartYard.gray.withAlphaComponent(0.5)
            titleLabel?.textColor = UIColor.SmartYard.gray.withAlphaComponent(0.5)
        default:
            break
        }
    }
    
}
