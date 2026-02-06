//
//  CustomDayCell.swift
//  SmartYard
//
//  Created by Mad Brains on 15.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import JTAppleCalendar

final class CustomDayCell: JTACDayCell {
    
    @IBOutlet private var selectedView: UIView!
    @IBOutlet private var dayLabel: UILabel!
    
    @IBOutlet private weak var bottomSeparatorView: UIView!
    @IBOutlet private var bottomSeparatorHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bottomSeparatorHeightConstraint.constant = 0.5
    }
    
    func configure(with state: CellState, isValidDate: Bool) {
        dayLabel.text = state.text
        
        selectedView.isHidden = !state.isSelected
        
        let textColor: UIColor? = {
            guard !state.isSelected else {
                return .SmartYard.secondBackgroundColor
            }
            
            return isValidDate ? .SmartYard.semiBlack : .SmartYard.semiBlack.withAlphaComponent(0.5)
        }()
        
        dayLabel.textColor = textColor
    }
    
}
