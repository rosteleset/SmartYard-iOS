//
//  ProviderCell.swift
//  SmartYard
//
//  Created by LanTa on 13.06.2022.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

final class ProviderCell: UITableViewCell {

    @IBOutlet private weak var checkBox: SmartYardCheckBoxView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    private var currentState: SmartYardCheckBoxState = .uncheckedActive {
        didSet {
            checkBox.setState(state: currentState)
        }
    }
    
    private func configureUI() {
        titleLabel.text = L10n.Auth.ProviderSelection.Method.maskedContactPlaceholder
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
        titleLabel.text = nil
    }
    
    func configure(with text: String, state: SmartYardCheckBoxState) {
        currentState = state
        titleLabel.text = text
    }
    
}
