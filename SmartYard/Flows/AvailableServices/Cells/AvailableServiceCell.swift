//
//  AvailableServiceCell.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class AvailableServiceCell: UITableViewCell {

    @IBOutlet private weak var checkBox: SmartYardCheckBoxView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    private var currentState: ServiceState = .uncheckedActive {
        didSet {
            titleLabel.textColor = currentState.titleTextColor
            descriptionLabel.textColor = currentState.descriptionTextColor
            checkBox.setState(state: currentState)
        }
    }

    func toogleState() {
        guard currentState != .checkedInactive else {
            return
        }
        
        currentState = currentState == .uncheckedActive ? .checkedActive : .uncheckedActive
    }
    
    func setState(state: ServiceState) {
        currentState = state
    }
    
}
