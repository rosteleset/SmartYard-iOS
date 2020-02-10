//
//  SettingsAddAddressCell.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class SettingsAddAddressCell: UICollectionViewCell {
    
    @IBOutlet private weak var addAddressButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }
    
    private func configure() {
        addAddressButton.borderWidth = 1
        addAddressButton.borderColor = UIColor.SmartYard.blue
    }

}
