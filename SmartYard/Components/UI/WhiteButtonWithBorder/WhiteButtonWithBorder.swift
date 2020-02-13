//
//  WhiteButtonWithBorder.swift
//  SmartYard
//
//  Created by Mad Brains on 07.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit

class WhiteButtonWithBorder: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        cornerRadius = 12
        backgroundColor = .white
        titleLabel?.textColor = UIColor.SmartYard.blue
        borderWidth = 1
        borderColor = UIColor.SmartYard.blue
    }
    
}
