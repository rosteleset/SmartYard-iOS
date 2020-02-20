//
//  AddressesListObjectCell.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class AddressesListObjectCell: CustomBorderCollectionViewCell {
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var openButton: ObjectLockButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure(objectType: .house, name: nil, isOpened: false)
    }
    
    func configure(objectType: DomophoneObjectType, name: String?, isOpened: Bool) {
        nameLabel.text = name
        iconImageView.image = objectType.icon
        openButton.isEnabled = !isOpened
    }

}
