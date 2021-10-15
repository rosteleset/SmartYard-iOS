//
//  SettingsActionCell.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class SettingsActionCell: CustomBorderCollectionViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configure(title: nil)
    }
    
    func configure(title: String?) {
        titleLabel.text = title
    }

}
