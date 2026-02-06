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
        let themeStyle = ThemeManager.shared.currentTheme.value

        let lightColor = color.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .light)
        )
        let darkColor = color.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .dark)
        )

        let themeColor: UIColor = {
            switch themeStyle {
            case .light: return lightColor
            case .dark: return darkColor

            case .unspecified:
                switch traitCollection.userInterfaceStyle {
                case .light: return lightColor
                case .dark: return darkColor
                default: return color
                }

            @unknown default:
                Logger.logWarning(
                    "Unknown ThemeManager style encountered: \(themeStyle)"
                )
                return color
            }
        }()

        DispatchQueue.main.async { [weak self] in
            guard let self, isSkeletonable else { return }

            hideSkeleton(reloadDataAfter: false)

            let gradient = SkeletonGradient(
                baseColor: themeColor,
                secondaryColor: themeColor.withAlphaComponent(0.2)
            )

            showAnimatedGradientSkeleton(usingGradient: gradient)
            startSkeletonAnimation()
        }
    }
}

// MARK: - Main thread helper

private extension UIView {
    func runOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
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

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let image = renderer.image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        return image
    }
}
