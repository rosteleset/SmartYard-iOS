//
//  AuthByContractNumViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 07.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class AuthByContractNumViewController: UIViewController {

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var containerView: UIView!
    
    @IBOutlet private weak var contractNumberTextField: SmartYardTextField!
    @IBOutlet private weak var passTextField: SmartYardTextField!
    
    @IBOutlet weak var forgetPassButton: ClearButtonWithDotsUnderline!
    @IBOutlet weak var forgetEverythingButton: ClearButtonWithDotsUnderline!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFieldPlaceholders()
    }
    
    private func configureTextFieldPlaceholders() {
        contractNumberTextField.setBoldPlaceholder(string: "Номер договора")
        passTextField.setBoldPlaceholder(string: "Пароль")
        forgetPassButton.setLeftAlignment()
        forgetEverythingButton.setRightAlignment()
    }

}
