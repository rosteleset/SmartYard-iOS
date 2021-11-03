//
//  PassConfirmationPinViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 23.03.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD

class PassConfirmationPinViewController: BaseViewController, LoaderPresentable {

    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var titleMessageLabel: UILabel!
    @IBOutlet private weak var pinTextField: PinTextField!
    
    // swiftlint:disable all
    @IBOutlet weak var sendCodeAgainButton: BlueButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var sendCodeAgainGroupView: UIView!
    @IBOutlet weak var sendCodeAgainMessageView: UIView!
    // swiftlint:enable all
    
    @IBOutlet private weak var sendCodeAgainGroupViewBottomConstraint: NSLayoutConstraint!
    
    var timer: Timer?
    var timeEnd: Date?
    
    var loader: JGProgressHUD?
    
    private let viewModel: PassConfirmationPinViewModel
    
    init(viewModel: PassConfirmationPinViewModel) {
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
        configureRxKeyboard()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        pinTextField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.isUserInteractionEnabled = true
    }
    
    private func configureView() {
        pinTextField.reset()
        sendCodeAgainMessageView.isHidden = false
        sendCodeAgainButton.isHidden = true
        sendCodeAgainGroupView.isHidden = false
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)

        runCodeTimer()
    }
    
    @objc private func dismissKeyboard() {
        pinTextField.hideKeyboard()
    }
    
    private func configureRxKeyboard() {
        RxKeyboard.instance.visibleHeight
            .drive(
                onNext: { [weak self] keyboardVisibleHeight in
                    self?.sendCodeAgainGroupViewBottomConstraint.constant = keyboardVisibleHeight == 0 ?
                        28 :
                        keyboardVisibleHeight
                    
                    UIView.animate(withDuration: 0) {
                        self?.view.layoutIfNeeded()
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
                    self?.sendCodeAgainMessageView.isHidden.toggle()
                    self?.runCodeTimer()
                }
            )
            .disposed(by: disposeBag)
        
        let text = pinTextField.rx.textControlProperty
            .orEmpty
            .observeOn(MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: "")
        
        let input = PassConfirmationPinViewModel.Input(
            inputPinText: text,
            sendCodeAgainButtonTapped: sendCodeAgainButton.rx.tap.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input: input)
        
        output.restoreMethod
            .drive(
                onNext: { method in
                    self.titleMessageLabel.text = method.displayedTextHasBeenSent
                }
            )
            .disposed(by: disposeBag)
        
        output.isPinCorrect
            .drive(
                onNext: { [weak self] isCorrect in
                    self?.pinTextField.markPass(isCorrect: isCorrect)
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
