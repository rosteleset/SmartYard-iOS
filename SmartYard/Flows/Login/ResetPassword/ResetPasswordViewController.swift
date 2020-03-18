//
//  ResetPasswordViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 18.03.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import JGProgressHUD

class ResetPasswordViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var contractTextField: SmartYardTextField!
    @IBOutlet private weak var firstResetMethodView: UIView!
    @IBOutlet private weak var secondResetMethodView: UIView!
    @IBOutlet private weak var getConfirmationCodeButton: WhiteButtonWithBorder!
    
    var loader: JGProgressHUD?
    
    let viewModel: ResetPasswordViewModel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    private func configureUI() {
        firstResetMethodView.isHidden = true
        secondResetMethodView.isHidden = true
    }
    
    private func bind() {
        
    }
    
}
