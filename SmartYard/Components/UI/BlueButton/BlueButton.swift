//
//  BlueButton.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit

class BlueButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        cornerRadius = 12
        backgroundColor = UIColor.SmartYard.blue
        titleLabel?.textColor = .white
    }
    
}
