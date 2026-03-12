//
//  BottomCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 26.01.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

final class BottomCell: UICollectionViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    private func configureUI() {
        titleLabel.text = L10n.Menu.Support.callToTechSupport
    }

}
