//
//  LinearGradientView.swift
//  SmartYard
//
//  Created by admin on 27.07.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

class LinearGradientView: UIView {
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    var gradientLayer: CAGradientLayer {
        guard let gradient = layer as? CAGradientLayer else {
            fatalError("Gradient Layer is missing")
        }
        return gradient
    }
    
    var colors: [UIColor] = [] {
        didSet {
            updateColors()
        }
    }
    
    var startPoint = CGPoint(x: 0.5, y: 0) {
        didSet {
            gradientLayer.startPoint = startPoint
        }
    }
    
    var endPoint = CGPoint(x: 0.5, y: 1) {
        didSet {
            gradientLayer.endPoint = endPoint
        }
    }
    
    init(frame: CGRect, colors: [UIColor] = []) {
        self.colors = colors
        super.init(frame: frame)
        gradientLayer.frame = frame
        updateColors()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateColors() {
        gradientLayer.colors = colors.map { $0.cgColor }
    }
    
}
