//
//  SmartYardCheckBoxView.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit
import PMNibLinkableView

class SmartYardCheckBoxView: PMNibLinkableView {
    
    @IBOutlet private weak var borderImageView: UIImageView!
    @IBOutlet private weak var checkImageView: UIImageView!
    
    private var currentState: SmartYardCheckBoxState = .uncheckedActive {
        didSet {
            borderImageView.tintColor = currentState.borderTintColor
            checkImageView.tintColor = currentState.checkTintColor
        }
    }

    func setState(state: SmartYardCheckBoxState) {
        currentState = state
    }
    
}
