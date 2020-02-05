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
    
    @IBOutlet private var numberFieldsOutletsCollection: [NumberFieldView]!
    
    @IBOutlet private weak var fakeTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureFakeTextField()
        configureNumberFields()
    }
    
    private func configureNumberFields() {
        numberFieldsOutletsCollection.forEach { view in
            view.clear()
            let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didPressNumberField(_:)))
            singleTapGesture.numberOfTapsRequired = 1
            view.addGestureRecognizer(singleTapGesture)
        }
    }
    
    @objc func didPressNumberField(_ sender: UITapGestureRecognizer? = nil) {
        print("here! \(sender)")
        fakeTextField.becomeFirstResponder()
    }
    
    private func configureFakeTextField() {
        fakeTextField.delegate = self
        fakeTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        fakeTextField.keyboardType = .numberPad
    }
    
}

extension PhoneTextField: UITextFieldDelegate {
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        
        guard let textFieldText = textField.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= 10
    }
    
}
