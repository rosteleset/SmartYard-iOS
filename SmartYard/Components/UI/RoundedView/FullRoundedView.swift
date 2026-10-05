//
//  FullRoundedView.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import Foundation
import UIKit

final class FullRoundedView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        registerForTraitChanges(
            UITraitCollection.systemTraitsAffectingColorAppearance,
            action: #selector(handleColorAppearanceChange)
        )
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        registerForTraitChanges(
            UITraitCollection.systemTraitsAffectingColorAppearance,
            action: #selector(handleColorAppearanceChange)
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
            
        layerCornerRadius = 12
        layerBorderWidth = 1
        addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
    }
    
}

extension FullRoundedView {
    
    @objc private func handleColorAppearanceChange() {
        self.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
    }
    
}
