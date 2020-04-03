//
//  PaymentAddressCell.swift
//  SmartYard
//
//  Created by Mad Brains on 02.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class PaymentAddressCell: UITableViewCell {

    @IBOutlet private weak var paymentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        paymentLabel.text = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16))
    }
    
    func configure(address: String) {
        paymentLabel.text = address
    }
    
}
