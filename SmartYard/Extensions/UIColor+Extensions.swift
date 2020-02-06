//
//  UIColor+Extensions.swift
//  SmartYard
//

//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

extension UIColor {
    
    enum SmartYard {
        /// #1FBC62
        static let darkGreen = UIColor(hex: 0x1FBC62)!
        
        /// #298BFF
        static let blue = UIColor(hex: 0x298BFF)!
        
        /// #F0F0F1
        static let grayBorder = UIColor(hex: 0xF0F0F1)!
        
        static var incorrectPinColor: UIColor {
            return UIColor(red: 1, green: 0.231, blue: 0.188, alpha: 1)
        }
    }
    
}

