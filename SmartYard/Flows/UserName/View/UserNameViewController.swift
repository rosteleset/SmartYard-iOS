//
//  UserNameViewController.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxKeyboard

class UserNameViewController: BaseViewController {

    @IBOutlet private weak var nameTextField: SmartYardTextField!
    @IBOutlet private weak var middleNameTextField: SmartYardTextField!
    @IBOutlet private weak var continueButton: UIButton!
    
    @IBOutlet private var mainContainerBottomConstraint: NSLayoutConstraint!
    
    private let viewModel: UserNameViewModel
    private let preloadedName: APIClientName?
    
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
