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
    @IBOutlet private weak var camerasLabel: UILabel!
    private func configureUI() {
        camerasLabel.text = L10n.Home.AddressCard.Cameras.cameras
        cameraCountLabel.text = L10n.Home.AddressCard.Cameras.countValue
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
        configure(availableCameras: 0)
    }
    
    func configure(availableCameras: Int) {
        cameraCountLabel.text = String(availableCameras)
    }

}
