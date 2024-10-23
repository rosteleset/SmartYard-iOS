//
//  FullRoundedView.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

final class FullRoundedView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
            
        layerCornerRadius = 12
        layerBorderWidth = 1
        layerBorderColor = UIColor.SmartYard.grayBorder
    }
    
}
