//
//  UIFont+Extensions.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

extension UIFont {
    
    enum SourceSansPro {
        static func regular(size fontSize: CGFloat) -> UIFont {
            return UIFont(name: "SourceSansPro-Regular", size: fontSize) ?? systemFont(ofSize: fontSize)
        }
        
        static func bold(size fontSize: CGFloat) -> UIFont {
            return UIFont(name: "SourceSansPro-Bold", size: fontSize) ?? regular(size: fontSize)
        }
        
        static func semibold(size fontSize: CGFloat) -> UIFont {
            return UIFont(name: "SourceSansPro-SemiBold", size: fontSize) ?? regular(size: fontSize)
        }
    }
    
}
