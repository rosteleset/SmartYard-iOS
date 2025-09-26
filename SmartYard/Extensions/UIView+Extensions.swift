//
//  UIView+Extensions.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit
import SkeletonView

extension UIView {

    @objc public func dismissKeyboard() {
        endEditing(true)
    }
    
    public var hideKeyboardWhenTapped: Bool {
        get {
            guard let number = objc_getAssociatedObject(
                self, &AssociatedKeys.hideKeyboardWhenTapped
                ) as? NSNumber else {
                    return false
            }
            return number.boolValue
        }
        set {
            if hideKeyboardWhenTapped != newValue {
                setActiveHideKeyboardGestureRecognizer(isActive: newValue)
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.hideKeyboardWhenTapped,
                    newValue,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
        }
    }
    
    // MARK: Private
    
    private enum AssociatedKeys {
        static var hideKeyboardWhenTapped = "hideKeyboardWhenTapped"
        static var gesture = "gesture"
    }
    
    private(set) var hideKeyboardGestureRecognizer: UIGestureRecognizer? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.gesture) as? UIGestureRecognizer
        }
        set {
            if let gesture = hideKeyboardGestureRecognizer {
                removeGestureRecognizer(gesture)
            }
            // weak reference
            objc_setAssociatedObject(self, &AssociatedKeys.gesture, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    private func setActiveHideKeyboardGestureRecognizer(isActive: Bool) {
        if isActive {
            let tap = UITapGestureRecognizer(target: self, action: #selector(UIView.dismissKeyboard))
            addGestureRecognizer(tap)
            tap.cancelsTouchesInView = false
            hideKeyboardGestureRecognizer = tap
        } else {
            hideKeyboardGestureRecognizer = nil
        }
    }
    
}

extension UIView {
    
    func showSkeletonAsynchronously(with color: UIColor) {
        let lightColor = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let darkColor = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        
        let themeColor: UIColor
        switch ThemeManager.shared.currentTheme.value {
        case .unspecified:
            switch traitCollection.userInterfaceStyle {
            case .dark:
                themeColor = darkColor
            case .light:
                themeColor = lightColor
            default:
                themeColor = color
            }
        case .light:
            themeColor = lightColor
        case .dark:
            themeColor = darkColor
        @unknown default:
            Logger.logWarning("Unknown ThemeManager style encountered: \(ThemeManager.shared.currentTheme.value)")
            themeColor = color
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isSkeletonable else { return }
            self.hideSkeleton()
            
            let gradient = SkeletonGradient(baseColor: themeColor, secondaryColor: themeColor.withAlphaComponent(0.2))
            showAnimatedGradientSkeleton(usingGradient: gradient)
        }
    }
    
}

extension UIView {
    func alignToView(_ parent: UIView) {
        NSLayoutConstraint.activate(
            [
                self.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 0),
                self.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: 0),
                self.topAnchor.constraint(equalTo: parent.topAnchor, constant: 0),
                self.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: 0)
            ]
        )
    }
}

extension UIView {
    func addBorder(dynamicColor: UIColor, width: CGFloat = 1.0) {
        self.layer.borderColor = dynamicColor.cgColor
        self.layer.borderWidth = width
    }
}
