//
//  SmartYardPasswordTextField.swift
//  SmartYard
//
//  Created by admin on 22.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import TouchAreaInsets

final class SmartYardPasswordTextField: SmartYardTextField {
    
    private let disposeBag = DisposeBag()
    
    private let visibilityButton: UIButton = {
        let button = UIButton(type: .custom)
        
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        
        button.configureSelectableButton(
            imageForNormal: UIImage(named: "ic_visibility_off"),
            imageForSelected: UIImage(named: "ic_visibility")
        )
        
        return button
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureUI()
    }
    
    override init() {
        super.init()
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: bounds.maxX - 20 - 24,
            y: (bounds.height - 24) / 2,
            width: 24,
            height: 24
        )
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20 + 20 + 24))
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20 + 20 + 24))
    }
    
    private func setPasswordVisible(_ visible: Bool) {
        isSecureTextEntry = !visible
        
        let originalSelectedRange = selectedTextRange

        if let existingText = text, isSecureTextEntry {
            /* When toggling to secure text, all text will be purged if the user
             continues typing unless we intervene. This is prevented by first
             deleting the existing text and then recovering the original text. */
            text = nil
            insertText(existingText)
            
            if let textRange = textRange(from: beginningOfDocument, to: endOfDocument) {
                replace(textRange, withText: existingText)
            }
        }

        /* Reset the selected text range since the cursor can end up in the wrong
         position after a toggle because the text might vary in width */
        if let existingSelectedTextRange = originalSelectedRange {
            selectedTextRange = nil
            selectedTextRange = existingSelectedTextRange
        }
    }
    
    private func configureUI() {
        tintColor = UIColor.SmartYard.semiBlack
        
        rightViewMode = .always
        
        rightView = visibilityButton
        
        visibilityButton.touchAreaInsets = UIEdgeInsets(inset: 20)
        
        visibilityButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    let newState = !self.visibilityButton.isSelected
                    
                    self.visibilityButton.isSelected = newState
                    
                    self.setPasswordVisible(newState)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
