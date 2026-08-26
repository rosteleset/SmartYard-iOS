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
        /// light: #1FBC62   :  dark: #6DC17D
        static let darkGreen = UIColor(named: "darkGreen")!
        
        /// light: #298BFF   :  dark: #4399FF
        static let blue = UIColor(named: "blue")!
        
        /// light: #F0F0F1   :  dark: #1F1F1F
        static let grayBorder = UIColor(named: "grayBorder")!
        
        /// light: #FF3B30   :  dark: #BB5146
        static let incorrectDataRed = UIColor(named: "incorrectDataRed")!
        
        /// light: #6D7A8A   :  dark: #A0A0A0
        static let gray = UIColor(named: "gray")!
        
        /// light: #28323E   :  dark: #E0E0E0
        static let semiBlack = UIColor(named: "semiBlack")!
        
        /// light: #F3F4FA   :  dark: #0A0A0A
        static let backgroundColor = UIColor(named: "backgroundColor")!
        
        /// light: #FFFFFF   :  dark: #191919
        static let secondBackgroundColor = UIColor(named: "secondBackgroundColor")!

        /// Foreground over a dark media scrim.
        /// light: secondBackgroundColor (#FFFFFF)   :  dark: semiBlack (#E0E0E0)
        static let mediaOverlayPrimary = UIColor { traits in
            let color = traits.userInterfaceStyle == .dark
                ? semiBlack
                : secondBackgroundColor
            return color.resolvedColor(with: traits)
        }

        /// Secondary foreground over a dark media scrim.
        /// light: secondBackgroundColor (#FFFFFF)   :  dark: gray (#A0A0A0)
        static let mediaOverlaySecondary = UIColor { traits in
            let color = traits.userInterfaceStyle == .dark
                ? gray
                : secondBackgroundColor
            return color.resolvedColor(with: traits)
        }

        /// Inactive page indicator over a dark media scrim.
        /// light: secondBackgroundColor at 35%   :  dark: gray (#A0A0A0)
        static let mediaOverlayInactiveIndicator = UIColor { traits in
            let color = traits.userInterfaceStyle == .dark
                ? gray
                : secondBackgroundColor.withAlphaComponent(0.35)
            return color.resolvedColor(with: traits)
        }
    }
    
    // TODO: - Заполнить остальные кастомные цвета сюда - 
    // Используется также кастомные цвета:
    //   1. Для ArrowIcons tintColor: #828282
    
    enum SYKeyboard {
        /// light: #E5E5EA   :  dark: #1C1C1E
        static let boardColor = UIColor(named: "boardColor")!
        
        /// light: #FFFFFF   :  dark: #2C2C2E
        static let keyColor = UIColor(named: "keyColor")!
        
        /// light: #D1D1D6   :  dark: #000000
        static let shadowKeyColor = UIColor(named: "shadowKeyColor")!
        
        /// light: #000000   :  dark: #FFFFFF
        static let textKeyColor = UIColor(named: "textKeyColor")!
    }
    
}
