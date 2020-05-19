//
//  CustomDayCell.swift
//  SmartYard
//
//  Created by Mad Brains on 15.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import JTAppleCalendar

class CustomDayCell: JTACDayCell {
    
    @IBOutlet private var selectedView: UIView!
    @IBOutlet private var dayLabel: UILabel!
    
    @IBOutlet private weak var bottomSeparatorView: UIView!
    @IBOutlet private var bottomSeparatorHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bottomSeparatorHeightConstraint.constant = 0.5
    }
    
    func configureDate(dayText: String) {
        dayLabel.text = dayText
    }
    
    func configureColor(from hex: Int) {
        dayLabel.textColor = UIColor(hex: hex)
    }
    
    func setSelectedViewVisibility(isHidden: Bool) {
        selectedView.isHidden = isHidden
    }
    
}
