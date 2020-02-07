//
//  AddressesListCameraCell.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class AddressesListCameraCell: CustomBorderCollectionViewCell {
    
    @IBOutlet private weak var cameraCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure(availableCameras: 0)
    }
    
    func configure(availableCameras: Int) {
        cameraCountLabel.text = String(availableCameras)
    }

}
