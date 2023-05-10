//
//  CamerasMapPointView.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import MapboxMaps
import PinLayout

class CamerasMapPointView: UIView {
    
    private(set) var cameraNumber: Int?
    private var tapCallback: (() -> Void)?
    
    private let cameraImageView: UIImageView = {
        let imageView = UIImageView()
        
        imageView.contentMode = .scaleAspectFill
//        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "CameraIcon")
//        imageView.image = UIImage(named: "CameraIcon")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .white
//        imageView.tintColor = UIColor.SmartYard.blue
//        imageView.tintColor = UIColor.SmartYard.gray

        return imageView
    }()
    
    private let cameraNumberLabel: UILabel = {
        let label = UILabel()
        
        label.font = UIFont.SourceSansPro.semibold(size: 14)
        label.textColor = UIColor.SmartYard.blue
        label.textAlignment = .center
        
        return label
    }()

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        
        backgroundColor = UIColor.SmartYard.blue
//        backgroundColor = .white
        
        addSubview(cameraImageView)
//        addSubview(cameraNumberLabel)
    
        clipsToBounds = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.addGestureRecognizer(tapGesture)
    }

    @objc func handleTap(sender: UITapGestureRecognizer) {
        self.tapCallback?()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        layerCornerRadius = width / 2
        
        cameraImageView.pin.width(24).height(24).top(8).hCenter()
//        cameraImageView.pin.width(15).height(13).top(8).hCenter()
//        cameraNumberLabel.pin.height(15).below(of: cameraImageView).hCenter().sizeToFit(.height)
    }
    
    func configure(cameraNumber: Int, _ onTap: @escaping (() -> Void)) {
        self.cameraNumber = cameraNumber
        self.tapCallback = onTap
//        cameraNumberLabel.text = "\(cameraNumber)"
    }
    
}
