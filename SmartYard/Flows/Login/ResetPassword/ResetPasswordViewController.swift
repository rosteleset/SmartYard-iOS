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
    @IBOutlet private weak var actionButton: WhiteButtonWithBorder!
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var methodsNotFoundLabel: UILabel!
    
    var loader: JGProgressHUD?
    
    let viewModel: ResetPasswordViewModel
    
    private let getResetMethodsText = "Получить доступные методы восстановления"
    private let getResetCodeText = "Получить код восстановления"
    
    init(viewModel: ResetPasswordViewModel) {
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

    private func configureUI() {
        firstResetMethodView.isHidden = true
        secondResetMethodView.isHidden = true
        methodsNotFoundLabel.isHidden = true
    }
    
    private func bind() {
        let input = ResetPasswordViewModel.Input(
            inputContractNum: contractTextField.rx.text.asDriver(onErrorJustReturn: nil),
            actionTrigger: actionButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input: input)
        
        output.shouldLoadResetMethodsTrigger
            .drive(
                onNext: { [weak self] in
                    self?.configureNeedReloadResetMethodsScene()
                }
            )
            .disposed(by: disposeBag)
        
        output.resetMethods
            .drive(
                onNext: { [weak self] resetMethods in
                    self?.configureResetMethodsScene(resetMethods: resetMethods)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureResetMethodsScene(resetMethods: [ResetMethodType]) {
        actionButton.setTitle(getResetCodeText, for: .normal)
        
        guard !resetMethods.isEmpty else {
            configureMethodsNotFoundScene()
            return
        }
        
        resetMethods.count == 1 ? configureOneMethodScene() : configureBothMethodScene()
    }
    
    private func configureMethodsNotFoundScene() {
        firstResetMethodView.isHidden = true
        secondResetMethodView.isHidden = true
        separatorView.isHidden = true
        methodsNotFoundLabel.isHidden = false
        
        actionButton.isEnabled = false
    }
    
    private func configureOneMethodScene() {
        firstResetMethodView.isHidden = false
        secondResetMethodView.isHidden = true
        separatorView.isHidden = true
        methodsNotFoundLabel.isHidden = true
        
        actionButton.isEnabled = true
    }
    
    private func configureBothMethodScene() {
        firstResetMethodView.isHidden = true
        secondResetMethodView.isHidden = true
        separatorView.isHidden = true
        methodsNotFoundLabel.isHidden = false
        
        actionButton.isEnabled = true
    }
    
    private func configureNeedReloadResetMethodsScene() {
        firstResetMethodView.isHidden = true
        secondResetMethodView.isHidden = true
        separatorView.isHidden = true
        methodsNotFoundLabel.isHidden = true
        
        actionButton.setTitle(getResetMethodsText, for: .normal)
    }
    
}
