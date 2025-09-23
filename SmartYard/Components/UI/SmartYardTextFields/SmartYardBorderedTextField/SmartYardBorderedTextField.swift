//
//  SmartYardBorderedTextField.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class SmartYardBorderedTextField: UITextField {

    var validator: TextValidation?

    var isValid: Bool {
        guard let validator else { return true }
        return validator.validate(text ?? "")
    }

    init() {
        super.init(frame: .zero)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureUI()
    }

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
                .foregroundColor: UIColor.SmartYard.gray.withAlphaComponent(0.4) as Any
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
                .foregroundColor: UIColor.SmartYard.gray.withAlphaComponent(0.4) as Any,
                .baselineOffset: 3
            ]
        )
        
        attributedPlaceholder = attrString + requirementString
    }

    @objc private func onEditingChanged() {
        updateBorder(valid: isValid)
    }

    @objc private func onEditingDidEnd() {
        let valid = isValid
        updateBorder(valid: valid)
        if !valid, let msg = validator?.errorMessage {
            // TODO: - показать ошибку
            // TODO: - сделать уведомление по нормальному, мб после добавления всплывашки VPN.
        }
    }

    func configure(with validator: TextValidation) {
        self.validator = validator
        addTarget(self, action: #selector(onEditingChanged), for: .editingChanged)
        addTarget(self, action: #selector(onEditingDidEnd), for: .editingDidEnd)
    }

    private func configureUI() {
        tintColor = UIColor.SmartYard.semiBlack
        layer.borderWidth = 1
        layer.borderColor = UIColor.clear.cgColor
    }

    private func updateBorder(valid: Bool) {
        layer.borderColor = valid ? UIColor.clear.cgColor : UIColor.SmartYard.incorrectDataRed.cgColor
    }

}
