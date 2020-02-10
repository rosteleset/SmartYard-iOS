//
//  ClearButtonWithDotsSubline.swift
//  SmartYard
//
//  Created by Mad Brains on 10.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit

class ClearButtonWithDotsUnderline: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundColor = .clear
        titleLabel?.textColor = UIColor.SmartYard.blue
        
        setUnderlinedTitle()
    }
    
    private func setUnderlinedTitle() {
        _ = layer.sublayers?
            .filter({ $0.name == "DashedTopLine" })
            .map({ $0.removeFromSuperlayer() })
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.name = "DashedTopLine"
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.SmartYard.blue.cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.lineDashPattern = [3, 3]
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: frame.height))
        path.addLine(to: CGPoint(x: frame.width, y: frame.height))
        shapeLayer.path = path
        
        layer.addSublayer(shapeLayer)
    }
    
    func setLeftAlignment() {
        titleLabel?.textAlignment = .left
    }
    
    func setRightAlignment() {
        titleLabel?.textAlignment = .right
    }
    
}
