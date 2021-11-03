//
//  NSAttributedString+Extensions.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

extension NSAttributedString {
    
    static func + (left: NSAttributedString, right: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        result.append(left)
        result.append(right)
        
        return result
    }
    
}
