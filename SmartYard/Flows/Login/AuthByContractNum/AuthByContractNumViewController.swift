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
    
    @IBOutlet private weak var noContractButton: WhiteButtonWithBorder!
    @IBOutlet private weak var signInButton: BlueButton!
    
    let viewModel: AuthByContractNumViewModel
    
    init(viewModel: AuthByContractNumViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        roundedView.roundCorners(
            [.topLeft, .topRight, .bottomLeft, .bottomRight],
            radius: 20.0
        )
    }
    
    private func bind() {
        _ = AuthByContractNumViewModel.Input(
            forgetPassTapped: forgetPassButton.rx.tap.asDriverOnErrorJustComplete(),
            forgetEverythingTapped: forgetEverythingButton.rx.tap.asDriverOnErrorJustComplete(),
            noContractTapped: noContractButton.rx.tap.asDriverOnErrorJustComplete(),
            signInTapped: signInButton.rx.tap.asDriverOnErrorJustComplete())
    }
    
    private func configureUI() {
        contractNumberTextField.setBoldPlaceholder(string: "Номер договора")
        passTextField.setBoldPlaceholder(string: "Пароль")
        forgetPassButton.setLeftAlignment()
        forgetEverythingButton.setRightAlignment()
    }

}
