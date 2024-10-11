//
//  PinCodeViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import UIKit
import RxCocoa
import RxSwift
import RxViewController
import JGProgressHUD

class PinCodeViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var hintInputPhoneLabel: UILabel!
    @IBOutlet private weak var fixPhoneNumberButton: UIButton!
    @IBOutlet private weak var sendCodeAgainGroupView: UIView!
    
    @IBOutlet private weak var pinInputFieldView: PinTextField!
    @IBOutlet private weak var containerView: TopRoundedView!
    
    @IBOutlet private var sendCodeAgainGroupButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var sendCodeAgainLabelView: UIView!
    @IBOutlet weak var sendCodeAgainButton: BlueButton!

    private let viewModel: PinCodeViewModel
    private let isInitial: Bool
    
    var timer: Timer?
    var timeEnd: Date?
    var loader: JGProgressHUD?
    
    init(viewModel: PinCodeViewModel, isInitial: Bool) {
        self.viewModel = viewModel
        self.isInitial = isInitial
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
        configureRxKeyboard()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        pinInputFieldView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.isUserInteractionEnabled = true
    }
    
    private func configureView() {
        pinInputFieldView.reset()
        sendCodeAgainLabelView.isHidden = true
        sendCodeAgainButton.isHidden = false
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        if isInitial {
            sendCodeAgainButton.isHidden.toggle()
            sendCodeAgainLabelView.isHidden.toggle()
            runCodeTimer()
        }
    }
    
    @objc private func dismissKeyboard() {
        pinInputFieldView.hideKeyboard()
    }
    
    private func configureRxKeyboard() {
        RxKeyboard.instance.visibleHeight
            .drive(
                onNext: { [weak self] keyboardVisibleHeight in
                    guard let self = self else {
                        return
                    }
                    self.sendCodeAgainGroupButtonConstraint.constant = (keyboardVisibleHeight == 0) || (self.view.frame.height == keyboardVisibleHeight) ?
                        28 :
                        keyboardVisibleHeight + 28
                    
                    UIView.animate(withDuration: 0) {
                        self.view.layoutIfNeeded()
                    }
                }
            )
            .disposed(by: disposeBag)
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
        
        let text = pinInputFieldView.rx.textControlProperty
            .orEmpty
            .observe(on: MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: "")
        
        let input = PinCodeViewModel.Input(
            inputPinText: text,
            fixPhoneNumberButtonTapped: fixPhoneNumberButton.rx.tap.asDriverOnErrorJustComplete(),
            sendCodeAgainButtonTapped: sendCodeAgainButton.rx.tap.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input: input)
        
        output.phoneNumber
            .drive(
                onNext: { phoneNumber in
                    self.hintInputPhoneLabel.text = "Введите код из СМС,\nотправленный на номер +7\(phoneNumber)"
                }
            )
            .disposed(by: disposeBag)
        
        output.isPinCorrect
            .drive(
                onNext: { [weak self] isCorrect in
                    self?.pinInputFieldView.markPass(isCorrect: isCorrect)
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
// swiftlint:enable function_body_length
