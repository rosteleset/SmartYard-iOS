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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leftDotView.cornerRadius = leftDotView.frame.size.width / 2
        centerDotView.cornerRadius = centerDotView.frame.size.width / 2
        rightDotView.cornerRadius = rightDotView.frame.size.width / 2
    }
    
    func updateContentOffset() {
        
    }
    
}
