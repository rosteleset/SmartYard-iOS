//
//  CACornerMask+Extensions.swift
//  SmartYard
//
//  Created by admin on 07/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

extension CACornerMask {
    
    static let bottomCorners: CACornerMask = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    
    static let topCorners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    
    static let leftCorners: CACornerMask = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
    
    static let rightCorners: CACornerMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    
}
