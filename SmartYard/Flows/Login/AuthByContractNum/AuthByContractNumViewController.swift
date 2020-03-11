//
//  AuthByContractNumViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 07.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import TPKeyboardAvoiding
import RxSwift
import RxCocoa
import JGProgressHUD

class AuthByContractNumViewController: BaseViewController, LoaderPresentable {

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var containerView: UIView!
    
    @IBOutlet private weak var contractNumberTextField: SmartYardTextField!
    @IBOutlet private weak var passTextField: SmartYardTextField!
    @IBOutlet private weak var roundedView: UIView!
    
    @IBOutlet private weak var forgetPassButton: ClearButtonWithDashedUnderline!
    @IBOutlet private weak var forgetEverythingButton: ClearButtonWithDashedUnderline!
    
    @IBOutlet private weak var noContractButton: WhiteButtonWithBorder!
    @IBOutlet private weak var signInButton: BlueButton!
    
    private let viewModel: AuthByContractNumViewModel
    
    var loader: JGProgressHUD?
    
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

    private func bind() {
        let input = AuthByContractNumViewModel.Input(
            forgetPassTapped: forgetPassButton.rx.tap.asDriverOnErrorJustComplete(),
            forgetEverythingTapped: forgetEverythingButton.rx.tap.asDriverOnErrorJustComplete(),
            noContractTapped: noContractButton.rx.tap.asDriverOnErrorJustComplete(),
            signInTapped: signInButton.rx.tap.asDriverOnErrorJustComplete(),
            inputContractNumText: contractNumberTextField.rx.text.changed.asDriver(onErrorJustReturn: nil),
            inputPasswordNumText: passTextField.rx.text.changed.asDriver(onErrorJustReturn: nil)
        )
        
        let output = viewModel.transform(input: input)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    if isLoading {
                        self?.view.endEditing(true)
                    }
                    
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureUI() {
        contractNumberTextField.setPlaceholder(string: "Номер договора", isSemiBold: true)
        passTextField.setPlaceholder(string: "Пароль", isSemiBold: true)
        
        forgetPassButton.setLeftAlignment()
        forgetEverythingButton.setRightAlignment()
        
        view.hideKeyboardWhenTapped = true
    }

}
