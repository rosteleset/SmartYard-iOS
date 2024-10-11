//
//  CheckBoxView.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 02.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation
import UIKit
import PMNibLinkableView

class CheckBoxView: PMNibLinkableView {
    
    @IBOutlet private weak var checkImageView: UIImageView!
    
    private var currentState: CheckBoxState = .unchecked {
        didSet {
            checkImageView.image = currentState.iconImage
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
    
    func setState(state: CheckBoxState) {
        currentState = state
    }
    
}
