//
//  JumpAvoidingFlowLayout.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class JumpAvoidingFlowLayout: UICollectionViewFlowLayout {
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else {
            return proposedContentOffset
        }
        
        if collectionViewContentSize.height <= collectionView.bounds.size.height {
            return CGPoint(x: proposedContentOffset.x, y: 0)
        }
        
        return proposedContentOffset
    }
    
}
