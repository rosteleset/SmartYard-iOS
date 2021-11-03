//
//  YTCollectionViewCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 17.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class YTCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var bottomSeparator: UIView!
    @IBOutlet private weak var topSeparator: UIView!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureCell(label: String, isFirst: Bool) {
        
        if isFirst { // ячейка первая - русуем верхний и нижний сепаратор
            self.topSeparator.isHidden = true
        } else { // ячейка в центре списка или последняя - рисуем только нижний сепаратор
            self.topSeparator.isHidden = true
        }
        
        self.bottomSeparator.isHidden = false
        self.label.text = label
    }
}
