//
//  SettingsHeaderCell.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class SettingsHeaderCell: CustomBorderCollectionViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var arrowImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configure(title: nil, subtitle: nil, isExpanded: false)
    }
    
    func configure(title: String?, subtitle: String?, isExpanded: Bool) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        
        arrowImageView.image = isExpanded ?
            UIImage(named: "UpArrowIcon") :
            UIImage(named: "DownArrowIcon")
    }
    
}
