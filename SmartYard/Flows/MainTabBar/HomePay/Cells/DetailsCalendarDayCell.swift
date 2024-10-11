//
//  DetailsCalendarDayCell.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 19.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit
import JTAppleCalendar

class DetailsCalendarDayCell: JTACDayCell {
    
    @IBOutlet private var selectedView: UIView!
    @IBOutlet private var dayLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with state: CellState, isValidDate: Bool) {
        dayLabel.text = state.text
        
        let section = state.dateSection()
        let isSelectedMonth: Bool = state.date.month == section.month
        
        selectedView.isHidden = !state.isSelected || !isSelectedMonth
        
        let textColor: UIColor? = {
            guard !state.isSelected || !isSelectedMonth else {
                return .white
            }
            
            return (isSelectedMonth && isValidDate) ? UIColor.SmartYard.textAddon : .lightGray
        }()
        
        dayLabel.textColor = textColor
    }
    
}
