//
//  TimelineLayout.swift
//  SmartYard
//
//  Created by devcentra on 19.12.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit

class TimelineLayout: UICollectionViewFlowLayout {
    
    var currentItem = 0
    var currentTime: Date = Date()
    
    var cellHeight: CGFloat = 5.0
    var cellTime: Int = 60
    var upperDate: Date = Date()
    
    func setCellAttributes(height: CGFloat, time: Int) {
        cellHeight = height
        cellTime = time
    }
    
    func setUpperDate(_ date: Date){
        upperDate = date
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let cv = collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        currentItem = Int((cv.contentOffset.y + 49) / CGFloat(cellHeight))
        let seconds = currentItem * cellTime
        if let time = Calendar.novokuznetskCalendar.date(byAdding: .second, value: 0 - seconds, to: upperDate) {
            currentTime = time
        }
        
        return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
    }
}
