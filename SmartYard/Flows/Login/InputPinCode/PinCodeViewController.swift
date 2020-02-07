//
//  PinCodeViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PinCodeViewController: BaseViewController {

    @IBOutlet private weak var hintInputPhoneLabel: UILabel!
    @IBOutlet private weak var fixPhoneNumberButton: UIButton!
    @IBOutlet private weak var sendCodeAgainGroupView: UIView!
    @IBOutlet private weak var sendCodeAgainLabelView: UIView!
    @IBOutlet private weak var timerLabel: UILabel!
    @IBOutlet private weak var sendCodeAgainButton: BlueButton!
    @IBOutlet private weak var pinInputFieldView: PinTextField!
    
    @IBOutlet private weak var sendCodeAgainGroupButtonConstraint: NSLayoutConstraint!
    
    let viewModel: PinCodeViewModel
    
    init(viewModel: PinCodeViewModel) {
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
        pinInputFieldView.reset()
        sendCodeAgainLabelView.isHidden = true
        sendCodeAgainButton.isHidden = false
    }
    
    private func moveSendAgainGroup(to position: CGFloat) {
        UIView.animate(
            withDuration: 1,
            animations: { [weak self] in
                self?.sendCodeAgainGroupButtonConstraint.constant = position
                self?.view.layoutIfNeeded()
            }
        )
    }
    
    private func bind() {
        sendCodeAgainButton.rx.tap
            .subscribe(
                onNext: { [weak self] _ in
                    self?.sendCodeAgainButton.isHidden.toggle()
                    self?.sendCodeAgainLabelView.isHidden.toggle()
                    self?.pinInputFieldView.markPass(isCorrect: false)
                }
            )
            .disposed(by: disposeBag)
        
        getKeyboardHeightObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] height in
                    guard height != 0 else {
                        self?.moveSendAgainGroup(to: 28)
                        return
                    }
                    
                    self?.moveSendAgainGroup(to: 10 + height)
                }
            )
            .disposed(by: disposeBag)

        let input = PinCodeViewModel.Input(
            inputPinText: pinInputFieldView.getPinTextDriver(),
            fixPhoneNumberButtonTapped: fixPhoneNumberButton.rx.tap.asDriverOnErrorJustComplete(),
            sendCodeAgainButtonDidTapped: sendCodeAgainButton.rx.tap.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input: input)
        
        output.checkPinTrigger
            .drive(
                onNext: { [weak self] isCorrect in
                    self?.pinInputFieldView.markPass(isCorrect: isCorrect)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
