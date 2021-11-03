//
//  AddressesListCameraCell.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class AddressesListHistoryCell: CustomBorderCollectionViewCell {
    
    @IBOutlet private weak var labelContainer: UIView!
    @IBOutlet private weak var historyCountLabel: UILabel!
    @IBOutlet private weak var arrowImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure(itemsCount: 0)
    }
    
    func configure(itemsCount: Int) {
        if itemsCount > 0 {
            labelContainer.isHidden = false
            historyCountLabel.text = String(itemsCount)
        } else {
            labelContainer.isHidden = true
        }
    }

}
