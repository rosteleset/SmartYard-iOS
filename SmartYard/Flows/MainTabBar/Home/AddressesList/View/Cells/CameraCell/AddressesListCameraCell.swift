//
//  AddressesListCameraCell.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

final class AddressesListCameraCell: CustomBorderCollectionViewCell {
    
    @IBOutlet private weak var cameraCountLabel: UILabel!
    @IBOutlet private weak var arrowImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure(availableCameras: 0)
    }
    
    func configure(availableCameras: Int) {
        cameraCountLabel.text = String(availableCameras)
    }

}
