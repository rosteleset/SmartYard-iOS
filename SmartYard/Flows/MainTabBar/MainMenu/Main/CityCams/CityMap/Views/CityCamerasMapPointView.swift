//
//  CityCamerasMapPointView.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import MapboxMaps
import PinLayout

final class CityCamerasMapPointView: UIView {
    
    private(set) var cameraNumber: Int?
    
    private let cameraImageView: UIImageView = {
        let imageView = UIImageView()
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "CityCam")?.withRenderingMode(.alwaysOriginal)
        
        return imageView
    }()
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        
        backgroundColor = .none
        addSubview(cameraImageView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cameraImageView.pin.width(66).height(66).vCenter(4).hCenter()
    }
    
    func configure(cameraNumber: Int) {
        self.cameraNumber = cameraNumber
        
    }
    
}
