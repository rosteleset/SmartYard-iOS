//
//  AvailableServiceCell.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class AvailableServiceCell: UITableViewCell {

    @IBOutlet private weak var checkBox: SmartYardCheckBoxView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    private var currentState: SmartYardCheckBoxState = .uncheckedActive {
        didSet {
            titleLabel.textColor = currentState.titleTextColor
            descriptionLabel.textColor = currentState.descriptionTextColor
            checkBox.setState(state: currentState)
        }
    }
    
    func configure(with item: ServiceModel) {
        titleLabel.text = item.name
        descriptionLabel.text = item.description
        currentState = item.state
    }
    
}
