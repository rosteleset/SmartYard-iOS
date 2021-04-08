//
//  AddressesListCameraCell.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class AddressesListHistoryCell: CustomBorderCollectionViewCell {
    
    @IBOutlet private weak var historyCountLabel: UILabel!
    @IBOutlet private weak var arrowImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure(count: 0)
    }
    
    func configure(count: Int) {
        historyCountLabel.text = String(count)
    }

}
