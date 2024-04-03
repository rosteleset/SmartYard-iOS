//
//  CameraButton.swift
//  SmartYard
//
//  Created by Александр Попов on 17.03.2024.
//  Copyright © 2024 LanTa. All rights reserved.
//

import Foundation
import UIKit

protocol CameraButtonDelegate: AnyObject {
    func didTapCameraButton(cameraNumber: Int)
}

class CameraButton: UIButton {
    weak var delegate: CameraButtonDelegate?
    var cameraNumber: Int
    
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    init(cameraNumber: Int) {
        self.cameraNumber = cameraNumber
        super.init(frame: .zero)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layerCornerRadius = bounds.height / 2
    }
    
    private func setupButton() {
        layerBorderColor = UIColor.SmartYard.blue
        layerBorderWidth = 1
        titleColorForNormal = UIColor.SmartYard.semiBlack
        titleColorForSelected = .white
        
        translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel?.font = UIFont.SourceSansPro.semibold(size: 16)
        
        setTitle(String(cameraNumber), for: .normal)
        
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    private func updateAppearance() {
        switch isSelected {
        case true:
            backgroundColor = UIColor.SmartYard.blue
        case false:
            backgroundColor = UIColor.white
        }
    }
    
    @objc private func buttonTapped() {
        delegate?.didTapCameraButton(cameraNumber: cameraNumber)
    }
}
