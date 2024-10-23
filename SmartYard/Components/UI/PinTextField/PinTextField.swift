//
//  PinTextField.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import PMNibLinkableView
import RxSwift
import RxCocoa

final class PinTextField: PMNibLinkableView {
    
    @IBOutlet private weak var containerView: UIView!
    
    @IBOutlet private weak var firstNumField: PinNumberField!
    @IBOutlet private weak var secondNumField: PinNumberField!
    @IBOutlet private weak var thirdNumField: PinNumberField!
    @IBOutlet private weak var fourthNumField: PinNumberField!
    
    @IBOutlet private weak var wrongPassLabel: UILabel!
    @IBOutlet fileprivate weak var fakeTextField: UITextField!
    
    private var numberViewsCollection: [PinNumberField] {
        return [firstNumField, secondNumField, thirdNumField, fourthNumField]
    }
    
    private let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureFakeTextField()
        addViewTapGesture()
        bind()
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return fakeTextField.becomeFirstResponder()
    }
    
    func hideKeyboard() {
        fakeTextField.resignFirstResponder()
    }
    
    func fetchInputNumber() -> String? {
        return fakeTextField.text
    }
    
    func reset() {
        fakeTextField.clear()
        wrongPassLabel.isHidden = true
        
        numberViewsCollection.forEach { view in
            view.clear()
        }
    }
    
    func markPass(isCorrect: Bool) {
        wrongPassLabel.isHidden = isCorrect
        numberViewsCollection.forEach {
            $0.markValue(isCorrect: isCorrect)
        }
    }
    
    @objc private func didPressNumberField() {
        fakeTextField.becomeFirstResponder()
    }
    
    private func bind() {
        fakeTextField.rx.text.changed
            .subscribe(
                onNext: { [weak self] text in
                    guard let self = self else {
                        return
                    }
                    
                    self.fillNumberFields(with: text)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func addViewTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didPressNumberField))
        containerView.addGestureRecognizer(tapGesture)
    }
    
    private func fillNumberFields(with text: String?) {
        numberViewsCollection.enumerated().forEach { offset, element in
            guard element.fetchValue() != text?[safe: offset]?.string else {
                return
            }
            
            element.setNewValue(value: text?[safe: offset]?.string)
        }
    }
    
    private func configureFakeTextField() {
        fakeTextField.delegate = self
        fakeTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        fakeTextField.keyboardType = .numberPad
        
        if #available(iOS 12.0, *) {
            fakeTextField.textContentType = .oneTimeCode
        }
    }
    
}

extension PinTextField: UITextFieldDelegate {
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let textFieldText = textField.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText)
            else {
                return false
        }
        
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        
        return count <= Constants.pinLength
    }
    
}

extension Reactive where Base: PinTextField {
    
    var textControlProperty: ControlProperty<String?> {
        return base.fakeTextField.rx.text
    }
    
}

