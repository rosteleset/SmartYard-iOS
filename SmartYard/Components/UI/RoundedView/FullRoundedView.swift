//
//  FullRoundedView.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit

class FullRoundedView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
            
        cornerRadius = 12
        borderWidth = 1
        borderColor = UIColor.SmartYard.grayBorder
    }
    
}
