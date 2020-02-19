//
//  LimitedTextField.swift
//  SmartYard
//
//  Created by Mad Brains on 18.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit

class LimitedTextField: UITextField {
    
    override func willMove(toSuperview newSuperview: UIView?) {
        addTarget(
            self,
            action: #selector(editingChanged),
            for: .editingChanged
        )
        
        editingChanged()
    }
    
    @objc func editingChanged() {
        guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: text ?? "")) else {
            text = ""
            return
        }
        
        guard let editText = text else {
            return
        }
        
        text = String(editText.prefix(Constants.phoneLengthWithoutPrefix))
    }
    
}
