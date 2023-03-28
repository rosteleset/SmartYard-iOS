//
//  GuestDoorCell.swift
//  SmartYard
//
//  Created by devcentra on 20.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit

class GuestDoorCell: CustomBorderCollectionViewCell {
    
    @IBOutlet private weak var arrowImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure(availableCameras: 0)
    }
    
    func configure(availableCameras: Int) {
//        cameraCountLabel.text = String(availableCameras)
    }
}
