//
//  CityCamerasMapPointView.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import Mapbox
import PinLayout

class CityCamerasMapPointView: MGLAnnotationView {
    
    private(set) var cameraNumber: Int?
    
    private let cameraImageView: UIImageView = {
        let imageView = UIImageView()
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "CityCam")?.withRenderingMode(.alwaysOriginal)
        
        return imageView
    }()
    
    convenience init() {
        self.init(reuseIdentifier: "CamerasMapPointView")
        
        scalesWithViewingDistance = false
        isEnabled = true
        
        backgroundColor = .none
        addSubview(cameraImageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cameraImageView.pin.width(66).height(66).vCenter(4).hCenter()
    }
    
    func configure(cameraNumber: Int) {
        self.cameraNumber = cameraNumber
        
    }
    
}
