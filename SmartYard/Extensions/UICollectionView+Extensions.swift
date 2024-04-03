//
//  UICollectionView+Extensions.swift
//  SmartYard
//
//  Created by Александр Попов on 22.03.2024.
//  Copyright © 2024 LanTa. All rights reserved.
//

import UIKit

extension UICollectionView {
    func getCenterPoint() -> CGPoint? {
        let centerPoint = CGPoint(x: contentOffset.x + bounds.size.width / 2,
                                  y: contentOffset.y + bounds.size.height / 2)
        return centerPoint
    }
}
