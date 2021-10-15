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
        
        circleView.borderWidth = 1
        circleView.borderColor = UIColor.SmartYard.blue
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        circleView.cornerRadius = frame.width / 2
    }
    
    func configure(curCamera: CameraObject) {
        cameraNumberLabel.text = String(curCamera.cameraNumber)
    }
    
}
