//
//  BlueButton.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

final class BlueButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    private func setupUI() {
        layerCornerRadius = 12
        backgroundColor = UIColor.SmartYard.blue
        titleLabel?.textColor = .white
        tintColor = .white
    }
    
    override var isEnabled: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    private func updateAppearance() {
        switch state {
        case .normal:
            backgroundColor = UIColor.SmartYard.blue
        case .disabled:
            backgroundColor = UIColor.SmartYard.gray.withAlphaComponent(0.5)
        default:
            break
        }
    }
    
}
