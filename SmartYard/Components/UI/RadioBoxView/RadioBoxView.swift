//
//  RadioBoxView.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 02.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation
import UIKit
import PMNibLinkableView

class RadioBoxView: PMNibLinkableView {
    
    @IBOutlet private weak var radioImageView: UIImageView!
    
    private var currentState: RadioBoxState = .unchecked {
        didSet {
            radioImageView.image = currentState.iconImage
        }
    }

    func changeState() {
        switch currentState {
        case .checked:
            currentState = .unchecked
        case .unchecked:
            currentState = .checked
        }
    }
    
    func setState(state: RadioBoxState) {
        currentState = state
    }
    
}
