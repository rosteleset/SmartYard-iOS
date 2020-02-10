//
//  SmartYardTextField.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class SmartYardTextField: UITextField {
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20))
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20))
    }

    func setPlaceholder(string: String, isRequiredField: Bool = false, isSemiBold: Bool = false) {
        let font = isSemiBold ? UIFont.SourceSansPro.semibold(size: 18)
                              : UIFont.SourceSansPro.regular(size: 18)
        
        let attrString = NSAttributedString(
            string: string,
            attributes: [
                .font: font,
                .foregroundColor: UIColor.SmartYard.placeholderGrayText.withAlphaComponent(0.4) as Any
            ]
        )
        
        guard isRequiredField else {
            attributedPlaceholder = attrString
            return
        }
        
        let requirementString = NSAttributedString(
            string: "*",
            attributes: [
                .font: font,
                .foregroundColor: UIColor.SmartYard.placeholderGrayText.withAlphaComponent(0.4) as Any,
                .baselineOffset: 3
            ]
        )
        
        attributedPlaceholder = attrString + requirementString
    }
    
}
