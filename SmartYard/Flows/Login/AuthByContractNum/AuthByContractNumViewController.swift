//
//  AuthByContractNumViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 07.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import TPKeyboardAvoiding
import RxSwift
import RxCocoa
import JGProgressHUD

final class AuthByContractNumViewController: BaseViewController, LoaderPresentable {

    @IBOutlet private weak var scrollView: TPKeyboardAvoidingScrollView!
    
    @IBOutlet private weak var contractNumberTextField: SmartYardBorderedTextField!
    @IBOutlet private weak var passTextField: SmartYardPasswordTextField!
    
    @IBOutlet private weak var roundedView: UIView!
    
    @IBOutlet private weak var forgetPassButton: ClearButtonWithDashedUnderline!
    @IBOutlet private weak var forgetEverythingButton: ClearButtonWithDashedUnderline!
    
    @IBOutlet private weak var noContractButton: WhiteButtonWithBorder!
    @IBOutlet private weak var signInButton: BlueButton!
    
    @IBOutlet private weak var headerView: HeaderView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    private let viewModel: AuthByContractNumViewModel
    
    var loader: JGProgressHUD?
    
    private let isShowingManual: Bool
    
    init(viewModel: AuthByContractNumViewModel, isShowingManual: Bool) {
        self.viewModel = viewModel
        self.isShowingManual = isShowingManual
        
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
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            inputContractNumText: contractNumberTextField.rx.text.asDriver(onErrorJustReturn: nil),
            inputPasswordNumText: passTextField.rx.text.asDriver(onErrorJustReturn: nil)
        )
        
        let output = viewModel.transform(input: input)
        
        output.isAbleToProceed
            .drive(
                onNext: { [weak self] isAbleToProceed in
                    self?.signInButton.isEnabled = isAbleToProceed
                }
            )
            .disposed(by: disposeBag)
        
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
        forgetPassButton.setTitle(L10n.Auth.ContractLogin.forgotPasswordButton, for: .normal)
        signInButton.setTitle(L10n.Auth.ContractLogin.loginButton, for: .normal)
        forgetEverythingButton.setTitle(L10n.Auth.ContractLogin.forgotCredentialsButton, for: .normal)
        noContractButton.setTitle(L10n.Auth.ContractLogin.iDonTHaveAContractButton, for: .normal)
        contractNumberTextField.setPlaceholder(
            string: L10n.Auth.ContractLogin.contractNumberPlaceholder,
            isSemiBold: true
        )
        passTextField.setPlaceholder(
            string: L10n.Auth.ContractLogin.passwordPlaceholder,
            isSemiBold: true
        )
        headerView.setText(
            L10n.Auth.ContractLogin.hasOperatorAgreementTitle,
            subtitle: L10n.Auth.ContractLogin.subtitle
        )

        forgetPassButton.setLeftAlignment()
        forgetEverythingButton.setRightAlignment()
        
        let tapGestureReconizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        passTextField.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEnd)
        tapGestureReconizer.cancelsTouchesInView = false
        tapGestureReconizer.delegate = self
        view.addGestureRecognizer(tapGestureReconizer)
        
        fakeNavBar.isHidden = !isShowingManual
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
        scrollView.setContentOffset(.zero, animated: true)
    }

}

extension AuthByContractNumViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: passTextField)
        
        return passTextField.hitTest(point, with: nil) == nil
    }
    
}
