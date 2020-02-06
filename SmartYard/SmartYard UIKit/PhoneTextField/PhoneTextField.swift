//
//  PhoneTextField.swift
//  SmartYard
//
//  Created by Mad Brains on 05.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit
import PMNibLinkableView
import RxSwift
import RxCocoa

class PhoneTextField: PMNibLinkableView {
    
    @IBOutlet private weak var firstNumView: NumberFieldView!
    @IBOutlet private weak var secondNumView: NumberFieldView!
    @IBOutlet private weak var thirdNumView: NumberFieldView!
    
    @IBOutlet private weak var fourthNumView: NumberFieldView!
    @IBOutlet private weak var fifthNumView: NumberFieldView!
    @IBOutlet private weak var sixthNumView: NumberFieldView!
    
    @IBOutlet private weak var seventhNumView: NumberFieldView!
    @IBOutlet private weak var eighthNumView: NumberFieldView!
    @IBOutlet private weak var ninthNumView: NumberFieldView!
    @IBOutlet private weak var tenthNumView: NumberFieldView!
    
    @IBOutlet private weak var fakeTextField: UITextField!
    
    private var numberViewsCollection = [NumberFieldView]()
    
    private var isFullNumbersSet = false
    private var countInputNumbers = 0
    
    private var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureFakeTextField()
        configureNumberFields()
        bind()
    }
    
    func fetchInputNumber() -> String? {
        return fakeTextField.text
    }
    
    func dismissKeybord() {
        fakeTextField.resignFirstResponder()
    }
    
    @objc private func didPressNumberField(_ sender: UITapGestureRecognizer? = nil) {
        guard !isFullNumbersSet else {
            clearAllNumberFields()
            fakeTextField.clear()
            return
        }
        
        fakeTextField.becomeFirstResponder()
    }
    
    private func bind() {
        fakeTextField.rx.text.changed
            .subscribe(
                onNext: { [weak self] text in
                    guard let self = self else {
                        return
                    }
                    
                    let newTextLength = text?.count ?? 0
                    
                    self.checkBackspacePressing(newTextLength: newTextLength)
                    self.checkFullSet(newTextLength: newTextLength)
                    self.fillNumberFields(with: text, position: newTextLength)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureNumberFields() {
        numberViewsCollection = [
            firstNumView, secondNumView, thirdNumView,
            fourthNumView, fifthNumView, sixthNumView,
            seventhNumView, eighthNumView, ninthNumView,
            tenthNumView
        ]
        
        numberViewsCollection.forEach { view in
            view.clear()
            let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didPressNumberField(_:)))
            view.addGestureRecognizer(singleTapGesture)
        }
    }
    
    private func fillNumberFields(with text: String?, position: Int) {
        guard position <= 10 else {
            return
        }
        
        let lastChar = text?.lastCharacterAsString
        numberViewsCollection[safe: position - 1]?.setNewValue(value: lastChar)
    }
    
    private func clearAllNumberFields() {
        numberViewsCollection.forEach { view in
            view.clear()
        }
    }
    
    private func configureFakeTextField() {
        fakeTextField.delegate = self
        fakeTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        fakeTextField.keyboardType = .numberPad
    }
    
    private func checkBackspacePressing(newTextLength: Int) {
        defer {
            countInputNumbers = newTextLength
        }
        
        guard countInputNumbers > newTextLength else {
            return
        }
        
        fillNumberFields(with: nil, position: self.countInputNumbers)
    }
    
    private func checkFullSet(newTextLength: Int) {
        isFullNumbersSet = newTextLength == 10
    }
    
}

extension PhoneTextField: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
              let rangeOfTextToReplace = Range(range, in: textFieldText)
        else {
              return false
        }
        
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        
        return count <= 10
    }
    
}
