//
//  YTCollectionViewCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 17.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class YTCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var separator: UIView!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureCell(label: String, isLast: Bool) {
        self.separator.isHidden = isLast
        self.label.text = label
    }
}
