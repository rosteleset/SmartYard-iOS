//
//  ProviderCell.swift
//  SmartYard
//
//  Created by LanTa on 13.06.2022.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class ProviderCell: UITableViewCell {

    @IBOutlet private weak var checkBox: SmartYardCheckBoxView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    private var currentState: SmartYardCheckBoxState = .uncheckedActive {
        didSet {
            checkBox.setState(state: currentState)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = nil
    }
    
    func configure(with text: String, state: SmartYardCheckBoxState) {
        currentState = state
        titleLabel.text = text
    }
    
}
