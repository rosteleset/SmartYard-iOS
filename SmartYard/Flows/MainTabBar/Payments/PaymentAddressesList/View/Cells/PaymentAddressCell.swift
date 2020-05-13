//
//  PaymentAddressCell.swift
//  SmartYard
//
//  Created by Mad Brains on 02.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class PaymentAddressCell: UICollectionViewCell {
    
    @IBOutlet private weak var paymentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        paymentLabel.text = nil
    }
    
    func configure(address: String) {
        paymentLabel.text = address
    }
    
}
