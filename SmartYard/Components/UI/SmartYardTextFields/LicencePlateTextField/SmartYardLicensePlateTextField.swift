//
//  SmartYardLicensePlateTextField.swift
//  SmartYard
//
//  Created by Александр Попов on 22.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PMNibLinkableView

class SmartYardLicensePlateTextField: UITextField, HasDisposeBag {
    
    
    private lazy var licencePlateKeyboard = LicencePlateKeyboardView.loadFromNib()
        
    override var inputView: UIView? {
        get { licencePlateKeyboard }
        set { }
    }
        
    var shareButtonTapped: Driver<Void> {
        licencePlateKeyboard.rx.shareButtonTapped.asDriver()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        bind()
        
        self.delegate = self
    }
    
    private func bind() {
        updateKeyboardKeys(for: "")
        
        self.rx
            .controlEvent(.editingChanged)
            .withLatestFrom(self.rx.text.orEmpty)
            .bind { [weak self] text in
                guard let self else { return }
                guard LicencePlateValidator.isValidPartialInput(
                    text,
                    format: self.licencePlateKeyboard.currentCountryMode
                ) else {
                    self.text = String(text.dropLast())
                    return
                }
            }
            .disposed(by: disposeBag)
        
        licencePlateKeyboard.onKeyPressed = { [weak self] key in
            guard let self else { return }

            let rawText = LicencePlateFormatter.unformat(text: self.text ?? "")
            let newRawText = rawText + key

            if LicencePlateValidator.isValidPartialInput(
                newRawText,
                format: licencePlateKeyboard.currentCountryMode
            ) {
                let formattedText = LicencePlateFormatter.format(
                    text: newRawText,
                    format: licencePlateKeyboard.currentCountryMode
                )
                self.text = formattedText
                
                self.updateKeyboardKeys(for: newRawText)
            }
        }

        licencePlateKeyboard.onDeletePressed = { [weak self] in
            guard let self else { return }

            let rawText = LicencePlateFormatter.unformat(text: self.text ?? "")
            guard !rawText.isEmpty else { return }

            let newRawText = String(rawText.dropLast())

            let formattedText = LicencePlateFormatter.format(
                text: newRawText,
                format: licencePlateKeyboard.currentCountryMode
            )
            self.text = formattedText
            
            self.updateKeyboardKeys(for: newRawText)
        }
        
    }
    
    private func updateKeyboardKeys(for rawText: String) {
        let allowed = LicencePlateValidator.allowedCharacters(
            for: rawText,
            format: licencePlateKeyboard.currentCountryMode
        )
        licencePlateKeyboard.setEnabledKeys(letters: allowed.letters, digits: allowed.digits)

        let isComplete = LicencePlateValidator.isCompleteInput(
            rawText,
            format: licencePlateKeyboard.currentCountryMode
        )
        licencePlateKeyboard.setShareButton(enabled: isComplete)
    }

}

extension SmartYardLicensePlateTextField: UITextFieldDelegate {
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return true
    }
    
}
