//
//  SmartYardCheckBoxView.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit
import PMNibLinkableView

class SmartYardCheckBoxView: PMNibLinkableView {
    
    @IBOutlet private weak var borderImageView: UIImageView!
    @IBOutlet private weak var checkImageView: UIImageView!
    
    private var currentState: ServiceState = .uncheckedActive {
        didSet {
            borderImageView.tintColor = currentState.borderTintColor
            checkImageView.tintColor = currentState.checkTintColor
        }
    }

    func setState(state: ServiceState) {
        currentState = state
    }
    
}
