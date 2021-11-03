//
//  CameraNumberCell.swift
//  SmartYard
//
//  Created by Mad Brains on 30.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class CameraNumberCell: UICollectionViewCell {

    @IBOutlet private weak var cameraNumberLabel: UILabel!
    @IBOutlet private weak var circleView: UIView!
    
    override var isSelected: Bool {
        didSet {
            circleView.backgroundColor = isSelected ? UIColor.SmartYard.blue : .white
            cameraNumberLabel.textColor = isSelected ? .white : UIColor.SmartYard.semiBlack
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        circleView.layerBorderWidth = 1
        circleView.layerBorderColor = UIColor.SmartYard.blue
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        circleView.layerCornerRadius = frame.width / 2
    }
    
    func configure(curCamera: CameraObject) {
        cameraNumberLabel.text = String(curCamera.cameraNumber)
    }
    
}
