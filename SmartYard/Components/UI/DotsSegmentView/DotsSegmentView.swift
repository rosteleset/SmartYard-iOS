//
//  DotsSegmentView.swift
//  SmartYard
//
//  Created by Mad Brains on 03.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit
import PMNibLinkableView

class DotsSegmentView: PMNibLinkableView {
    
    @IBOutlet private weak var leftDotView: UIView!
    @IBOutlet private weak var centerDotView: UIView!
    @IBOutlet private weak var rightDotView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        highlightLeftDot()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leftDotView.cornerRadius = leftDotView.frame.size.width / 2
        centerDotView.cornerRadius = centerDotView.frame.size.width / 2
        rightDotView.cornerRadius = rightDotView.frame.size.width / 2
    }
    
    func updateDotsViewIfNeeded(with currentIndex: Int, maxIndex: Int) {
        let curPercentOffset = (currentIndex * 100) / maxIndex
        
        let needHighlightLeftDot = curPercentOffset <= 33
        let needHighlightCenterDot = curPercentOffset > 33 && curPercentOffset < 66
        let needHighlightRightDot = curPercentOffset >= 66
        
        switch (needHighlightLeftDot, needHighlightCenterDot, needHighlightRightDot) {
        case (true, false, false): highlightLeftDot()
        case (false, true, false): highlightCenterDot()
        case (false, false, true): highlightRightDot()
        default: break
        }
    }
    
    private func highlightLeftDot() {
        leftDotView.backgroundColor = UIColor.SmartYard.blue
        centerDotView.backgroundColor = .white
        rightDotView.backgroundColor = .white
    }
    
    private func highlightCenterDot() {
        leftDotView.backgroundColor = .white
        centerDotView.backgroundColor = UIColor.SmartYard.blue
        rightDotView.backgroundColor = .white
    }
    
    private func highlightRightDot() {
        leftDotView.backgroundColor = .white
        centerDotView.backgroundColor = .white
        rightDotView.backgroundColor = UIColor.SmartYard.blue
    }
    
}
