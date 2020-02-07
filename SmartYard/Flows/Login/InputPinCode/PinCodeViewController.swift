//
//  PinCodeViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxViewController

class PinCodeViewController: BaseViewController {

    @IBOutlet private weak var hintInputPhoneLabel: UILabel!
    @IBOutlet private weak var fixPhoneNumberButton: UIButton!
    @IBOutlet private weak var sendCodeAgainGroupView: UIView!
    @IBOutlet private weak var pinInputFieldView: PinTextField!
    
    // swiftlint:disable all
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var sendCodeAgainLabelView: UIView!
    @IBOutlet weak var sendCodeAgainButton: BlueButton!
    // swiftlint:enable all
    
    @IBOutlet private weak var sendCodeAgainGroupButtonConstraint: NSLayoutConstraint!
    
    var timer: Timer?
    var timeEnd: Date?
    
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
        bind()
        configureView()
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
                    self?.runCodeTimer()
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
                    
                    self?.moveSendAgainGroup(to: 5 + height)
                }
            )
            .disposed(by: disposeBag)

        let input = PinCodeViewModel.Input(
            inputPinText: pinInputFieldView.getPinTextDriver(),
            fixPhoneNumberButtonTapped: fixPhoneNumberButton.rx.tap.asDriverOnErrorJustComplete(),
            sendCodeAgainButtonapped: sendCodeAgainButton.rx.tap.asDriverOnErrorJustComplete(),
            viewWillAppearTrigger: rx.viewWillAppear.asDriver(onErrorJustReturn: false)
        )
        
        let output = viewModel.transform(input: input)
        
        output.phoneNumberValueTrigger
            .drive(
                onNext: { phoneNumber in
                    self.hintInputPhoneLabel.text = "Введите код из СМС,\nотправленный на номер +7\(phoneNumber)"
                }
            )
            .disposed(by: disposeBag)
        
        output.checkPinTrigger
            .drive(
                onNext: { [weak self] isCorrect in
                    self?.pinInputFieldView.markPass(isCorrect: isCorrect)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
