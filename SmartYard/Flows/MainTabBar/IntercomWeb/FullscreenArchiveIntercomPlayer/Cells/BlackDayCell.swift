//
//  BlackDayCell.swift
//  SmartYard
//
//  Created by devcentra on 20.10.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit
import JTAppleCalendar

class BlackDayCell: JTACDayCell {
    
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
                return .white
            }
            
            return isValidDate ? .white : UIColor(hex: 0x2B2B2B)
        }()
        
        dayLabel.textColor = textColor
    }
    
}
