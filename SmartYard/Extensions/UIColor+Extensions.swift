//
//  UIColor+Extensions.swift
//  SmartYard
//

//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

extension UIColor {
    
    enum SmartYard {
        
        /// #1FBC62
        static let darkGreen = UIColor(hex: 0x1FBC62)!
        
        /// #298BFF
        static var blue: UIColor {
            if #available(iOS 13.0, *) {
                return UIColor { (traits) -> UIColor in
                    return traits.userInterfaceStyle == .dark ? UIColor(hex: 0xD61344)! : UIColor(hex: 0xE41A4C)!
                }
            } else {
                return UIColor(hex: 0xE41A4C)!
            }
        }
        
        /// #F0F0F1
        static let grayBorder = UIColor(hex: 0xF0F0F1)!
        
        /// #FF3B30
        static let incorrectDataRed = UIColor(hex: 0xFF3B30)!
        
        /// #6D7A8A
        static let gray = UIColor(hex: 0x6D7A8A)!
        
        /// #28323E
        static let semiBlack = UIColor(hex: 0x28323E)!
        
        /// #3E3228
        static let textAddon = UIColor(hex: 0x3E3228)!
        
        /// #F3F4FA
        static var backgroundColor: UIColor {
            if #available(iOS 13.0, *) {
                return UIColor { (traits) -> UIColor in
                    return traits.userInterfaceStyle == .dark ? UIColor(hex: 0x14161A)! : UIColor(hex: 0xF3F4FA)!
                }
            } else {
                return UIColor(hex: 0xF3F4FA)!
            }
        }
        
        /// #FFFFFF
        static var superWhite: UIColor {
            if #available(iOS 13.0, *) {
                return UIColor { (traits) -> UIColor in
                    return traits.userInterfaceStyle == .dark ? UIColor(hex: 0x000000)! : UIColor(hex: 0xFFFFFF)!
                }
            } else {
                return UIColor(hex: 0xFFFFFF)!
            }
        }
    }
}

