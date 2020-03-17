//
//  UnapprovedObjectCell.swift
//  SmartYard
//
//  Created by Mad Brains on 17.03.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class UnapprovedObjectCell: CustomBorderCollectionViewCell {

    @IBOutlet private weak var addressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configure(address: nil)
    }
    
    func configure(address: String?) {
        addressLabel.text = address
    }

}
