//
//  UserNameViewController.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxKeyboard
import JGProgressHUD

class UserNameViewController: BaseViewController, LoaderPresentable {

    @IBOutlet private weak var nameTextField: SmartYardTextField!
    @IBOutlet private weak var middleNameTextField: SmartYardTextField!
    @IBOutlet private weak var continueButton: UIButton!
    
    @IBOutlet private var mainContainerBottomConstraint: NSLayoutConstraint!
    
    private let viewModel: UserNameViewModel
    private let preloadedName: APIClientName?
    
    var loader: JGProgressHUD?
    
    init(viewModel: UserNameViewModel, preloadedName: APIClientName?) {
        self.viewModel = viewModel
        self.preloadedName = preloadedName
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureRxKeyboard()
        bind()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.isUserInteractionEnabled = true
    }
    
    private func configureView() {
        view.hideKeyboardWhenTapped = true
        
        nameTextField.setPlaceholder(string: "Имя", isRequiredField: true)
        nameTextField.delegate = self
        nameTextField.text = preloadedName?.name
        nameTextField.sendActions(for: .allEditingEvents)
        
        middleNameTextField.setPlaceholder(string: "Отчество")
        middleNameTextField.delegate = self
        middleNameTextField.text = preloadedName?.patronymic
        middleNameTextField.sendActions(for: .allEditingEvents)
    }
    
    private func configureRxKeyboard() {
        RxKeyboard.instance.visibleHeight
            .drive(
                onNext: { [weak self] keyboardVisibleHeight in
                    self?.mainContainerBottomConstraint.constant = keyboardVisibleHeight == 0 ?
                        0 :
                        keyboardVisibleHeight
                    
                    UIView.animate(withDuration: 0) {
                        self?.view.layoutIfNeeded()
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func bind() {
        let input = UserNameViewModel.Input(
            name: nameTextField.rx.text.asDriver(),
            middleName: middleNameTextField.rx.text.asDriver(),
            continueTrigger: continueButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input: input)
        
        output.isAbleToContinue
            .drive(continueButton.rx.isEnabled)
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
        
        output.prepareTransitionTrigger
            .drive(
                onNext: { [weak self] in
                    self?.view.endEditing(true)
                    self?.view.isUserInteractionEnabled = false
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension UserNameViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField: middleNameTextField.becomeFirstResponder()
        case middleNameTextField: middleNameTextField.resignFirstResponder()
        default: break
        }
        
        return true
    }
    
}
