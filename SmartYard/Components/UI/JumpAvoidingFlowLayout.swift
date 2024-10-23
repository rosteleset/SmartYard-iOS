//
//  JumpAvoidingFlowLayout.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

final class JumpAvoidingFlowLayout: UICollectionViewFlowLayout {
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else {
            return proposedContentOffset
        }
        
        if collectionViewContentSize.height <= collectionView.bounds.size.height {
            let refreshControlHeight: CGFloat = {
                guard let refreshControl = collectionView.refreshControl, refreshControl.isRefreshing else {
                    return 0
                }
                
                return refreshControl.bounds.height
            }()
            
            return CGPoint(x: proposedContentOffset.x, y: 0 - refreshControlHeight)
        }
        
        return proposedContentOffset
    }
    
}

