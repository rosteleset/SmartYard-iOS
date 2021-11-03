//
//  ServicesActivationRequestСell.swift
//  SmartYard
//
//  Created by Mad Brains on 13.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class ServicesActivationRequestСell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var checkBox: SmartYardCheckBoxView!
    
    private var currentState: SmartYardCheckBoxState = .uncheckedActive {
        didSet {
            titleLabel.textColor = currentState.titleTextColor
            checkBox.setState(state: currentState)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        checkBox.setState(state: .uncheckedActive)
    }

    func configure(with item: ServiceModel) {
        titleLabel.text = item.name
        currentState = item.state
    }
    
}
