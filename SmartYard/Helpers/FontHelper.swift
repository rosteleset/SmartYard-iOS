//
//  FontHelper.swift
//  SmartYard
//
//  Created by Александр Попов on 12.12.2024.
//  Copyright © 2024 Sesameware. All rights reserved.
//

import UIKit

protocol FontApplicable {
    func setFont(name: String, size: CGFloat)
}

extension FontApplicable where Self: UIView {
    func setFont(name: String, size: CGFloat) {
        if let textField = self as? UITextField {
            textField.font = UIFont(name: name, size: size)
        } else if let label = self as? UILabel {
            label.font = UIFont(name: name, size: size)
        } else if let button = self as? UIButton {
            button.titleLabel?.font = UIFont(name: name, size: size)
        }
    }
}

// Common extension for UITextField, UILabel, and UIButton
extension UITextField: FontApplicable {}
extension UILabel: FontApplicable {}
extension UIButton: FontApplicable {}

extension UIView {
    @IBInspectable var sansProRegular: CGFloat {
        get {
            return 0.0
        }
        set {
            (self as? FontApplicable)?.setFont(name: "SourceSansPro-Regular", size: newValue)
        }
    }

    @IBInspectable var sansProSemiBold: CGFloat {
        get {
            return 0.0
        }
        set {
            (self as? FontApplicable)?.setFont(name: "SourceSansPro-SemiBold", size: newValue)
        }
    }

    @IBInspectable var sansProBold: CGFloat {
        get {
            return 0.0
        }
        set {
            (self as? FontApplicable)?.setFont(name: "SourceSansPro-Bold", size: newValue)
        }
    }

}
