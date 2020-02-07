//
//  AddressExpandableHeaderCell.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class AddressesListHeaderCell: CustomBorderCollectionViewCell {
    
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var arrowImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure(address: nil, isExpanded: false)
    }
    
    func configure(address: String?, isExpanded: Bool) {
        addressLabel.text = address
        
        arrowImageView.image = isExpanded ?
            UIImage(named: "UpArrowIcon") :
            UIImage(named: "DownArrowIcon")
    }

}
