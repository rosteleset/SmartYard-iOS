//
//  CameraNameCell.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 14.03.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit

class CameraNameCell: UICollectionViewCell {

    @IBOutlet private weak var cameraNameLabel: UILabel!
    @IBOutlet private weak var cameraAddressLabel: UILabel!
    @IBOutlet weak var cameraSelectButton: CameraSelectButton!
    @IBOutlet weak var cameraDragImage: UIImageView!
    
    var tapGesture: UILongPressGestureRecognizer!
    var cameraNumber: Int?
    
    override var isSelected: Bool {
        didSet {
            cameraSelectButton.isHighlighted = isSelected
//            circleView.backgroundColor = isSelected ? UIColor.SmartYard.blue : .white
//            cameraNumberLabel.textColor = isSelected ? .white : UIColor.SmartYard.textAddon
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        circleView.layerBorderWidth = 1
//        circleView.layerBorderColor = UIColor.SmartYard.blue
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        circleView.layerCornerRadius = frame.width / 2
    }
    
    func configure(camera: CameraObject) {
        let cameraStrings = camera.name.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
        
        var cameraNameString = ""
        var cameraAddressString = ""
        
        if cameraStrings.count == 2 {
            cameraNameString = String(cameraStrings[0])
            cameraAddressString = String(cameraStrings[1])
        } else {
            cameraNameString = camera.name
        }
        
        cameraNameLabel.text = cameraNameString
        cameraAddressLabel.text = cameraAddressString
        cameraNumber = camera.cameraNumber

//        cameraNumberLabel.text = String(curCamera.cameraNumber)
    }
    
}
