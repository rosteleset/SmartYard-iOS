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
    @IBOutlet private weak var roundedView: UIView!
    
    @IBOutlet private weak var forgetPassButton: ClearButtonWithDotsUnderline!
    @IBOutlet private weak var forgetEverythingButton: ClearButtonWithDotsUnderline!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        roundedView.roundCorners([.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 20.0)
    }
    
    private func configureUI() {
        contractNumberTextField.setBoldPlaceholder(string: "Номер договора")
        passTextField.setBoldPlaceholder(string: "Пароль")
        forgetPassButton.setLeftAlignment()
        forgetEverythingButton.setRightAlignment()
    }

}
