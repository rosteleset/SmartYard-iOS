//
//  VideoPeriodPickerCell.swift
//  SmartYard
//
//  Created by admin on 02.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class VideoPeriodPickerCell: UICollectionViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.text = nil
        layerBorderColor = UIColor.SmartYard.gray
        layerCornerRadius = 3
        
        updateSelectedState(false)
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectedState(isSelected)
        }
    }
    
    func setTitle(_ title: String) {
        titleLabel.text = title
    }
    
    private func updateSelectedState(_ newState: Bool) {
        titleLabel.font = newState ?
            UIFont.SourceSansPro.bold(size: 14) :
            UIFont.SourceSansPro.regular(size: 14)
        
        layerBorderWidth = newState ? 1 : 0
    }

}
