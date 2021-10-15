//
//  CamerasMapPointView.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import Mapbox
import PinLayout

class CamerasMapPointView: MGLAnnotationView {
    
    private(set) var cameraNumber: Int?
    
    private let cameraImageView: UIImageView = {
        let imageView = UIImageView()
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "CameraIcon")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.SmartYard.gray
        
        return imageView
    }()
    
    private let cameraNumberLabel: UILabel = {
        let label = UILabel()
        
        label.font = UIFont.SourceSansPro.semibold(size: 14)
        label.textColor = UIColor.SmartYard.blue
        label.textAlignment = .center
        
        return label
    }()

    convenience init() {
        self.init(reuseIdentifier: "CamerasMapPointView")
        
        scalesWithViewingDistance = false
        isEnabled = true
        
        backgroundColor = .white
        
        addSubview(cameraImageView)
        addSubview(cameraNumberLabel)
    
        clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        cornerRadius = width / 2
        
        cameraImageView.pin.width(15).height(13).top(8).hCenter()
        cameraNumberLabel.pin.height(15).below(of: cameraImageView).hCenter().sizeToFit(.height)
    }
    
    func configure(cameraNumber: Int) {
        self.cameraNumber = cameraNumber
        
        cameraNumberLabel.text = "\(cameraNumber)"
    }
    
}
