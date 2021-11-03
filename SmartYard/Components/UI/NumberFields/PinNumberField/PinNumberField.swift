//
//  PinNumberField.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import PMNibLinkableView

class PinNumberField: PMNibLinkableView {

    @IBOutlet private weak var numberLabel: UILabel!
    @IBOutlet private weak var underlineView: UIView!
    
    func fetchValue() -> String? {
        return numberLabel.text
    }

    func clear() {
        numberLabel.text = nil
    }

    func setNewValue(value: String?) {
        numberLabel.text = value
    }
    
    func markValue(isCorrect: Bool) {
        underlineView.backgroundColor = isCorrect ? .black : UIColor.SmartYard.incorrectDataRed
    }

}
