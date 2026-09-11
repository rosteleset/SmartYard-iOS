//
//  FullRoundedView.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import Foundation
import UIKit

final class FullRoundedView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
            
        layerCornerRadius = 12
        layerBorderWidth = 1
        addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
    }
    
}

extension FullRoundedView {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        self.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
    }
    
}
