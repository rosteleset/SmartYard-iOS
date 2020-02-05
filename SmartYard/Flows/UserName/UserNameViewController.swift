//
//  UserNameViewController.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import IHKeyboardAvoiding

class UserNameViewController: BaseViewController {

    @IBOutlet private weak var nameTextField: SmartYardTextField!
    @IBOutlet private weak var middleNameTextField: SmartYardTextField!
    @IBOutlet private weak var continueButton: UIButton!
    @IBOutlet private weak var avoidingView: UIView!
    
    let viewModel: UserNameViewModel
    
    init(viewModel: UserNameViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        bind()
    }
    
    private func configureView() {
        view.hideKeyboardWhenTapped = true
        
        KeyboardAvoiding.avoidingView = avoidingView
        
        nameTextField.setPlaceholder(string: "Имя", isRequiredField: true)
        nameTextField.delegate = self
        
        middleNameTextField.setPlaceholder(string: "Отчество")
        middleNameTextField.delegate = self
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
