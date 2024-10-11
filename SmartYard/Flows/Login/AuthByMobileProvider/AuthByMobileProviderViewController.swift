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

class AuthByMobileProviderViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var hintInputPhoneLabel: UILabel!
    @IBOutlet private weak var sendConfirmAgainGroupView: UIView!
    
    @IBOutlet private weak var containerView: TopRoundedView!
    
    @IBOutlet private var sendConfirmAgainGroupButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var fixPhoneNumberButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var sendConfirmAgainLabelView: UIView!
    @IBOutlet weak var sendConfirmAgainButton: BlueButton!
    @IBOutlet weak var loaderView: UIView!

    private let viewModel: AuthByMobileProviderViewModel
    
    var timer: Timer?
    var timeEnd: Date?
    var timeShowFixButton: Date?
    var loader: JGProgressHUD?
    
    init(viewModel: AuthByMobileProviderViewModel) {
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.isUserInteractionEnabled = true
    }
    
    private func configureView() {
        sendConfirmAgainLabelView.isHidden = false
        sendConfirmAgainButton.isHidden = true
        fixPhoneNumberButton.isHidden = true
        
        runConfirmTimer()
    }
    
    private func bind() {
        sendConfirmAgainButton.rx.tap
            .subscribe(
                onNext: { [weak self] _ in
                    self?.sendConfirmAgainButton.isHidden.toggle()
                    self?.sendConfirmAgainLabelView.isHidden.toggle()
                    self?.fixPhoneNumberButton.isHidden.toggle()
                    self?.runConfirmTimer()
                }
            )
            .disposed(by: disposeBag)
        
        let input = AuthByMobileProviderViewModel.Input(
            fixPhoneNumberButtonTapped: fixPhoneNumberButton.rx.tap.asDriverOnErrorJustComplete(),
            sendConfirmAgainButtonTapped: sendConfirmAgainButton.rx.tap.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input: input)
        
        output.phoneNumber
            .drive(
                onNext: { phoneNumber in
                    self.hintInputPhoneLabel.text = "На номер +7\(phoneNumber) отправлено уведомление \nподтвердите доступ к приложению"
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    guard let self = self else {
                        return
                    }
                    self.updateLoader(isEnabled: isLoading, detailText: nil, loaderContainer: self.loaderView)
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
