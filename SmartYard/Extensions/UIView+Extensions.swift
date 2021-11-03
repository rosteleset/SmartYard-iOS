//
//  UIView+Extensions.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

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
    
    func showSkeletonAsynchronously() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.hideSkeleton()
            
            if self.isSkeletonable {
                self.showAnimatedGradientSkeleton()
            }
        }
    }
    
}
