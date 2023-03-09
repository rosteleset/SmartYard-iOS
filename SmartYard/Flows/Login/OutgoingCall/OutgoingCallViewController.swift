//
//  PinCodeViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxViewController
import JGProgressHUD

class OutgoingCallViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var hintInputPhoneLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var fixPhoneNumberButton: UIButton!
    @IBOutlet private weak var sendCodeAgainGroupView: UIView!
    
    @IBOutlet private weak var containerView: TopRoundedView!
    
    @IBOutlet private var sendCodeAgainGroupButtonConstraint: NSLayoutConstraint!
    
    // swiftlint:disable all
    @IBOutlet weak var makeCallButton: BlueButton!
    // swiftlint:enable all

    private let viewModel: OutgoingCallViewModel
    
    var loader: JGProgressHUD?
    
    init(viewModel: OutgoingCallViewModel) {
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
        makeCallButton.isHidden = false
    }
    
    private func bind() {
        let input = OutgoingCallViewModel.Input(
            fixPhoneNumberButtonTapped: fixPhoneNumberButton.rx.tap.asDriverOnErrorJustComplete(),
            makeCallButtonTapped: makeCallButton.rx.tap.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input: input)
        
        output.phoneNumber
            .drive(
                onNext: { phoneNumber in
                    self.hintInputPhoneLabel.text = "Нам необходимо убедиться,\n что номер +\(AccessService.shared.phonePrefix)\(phoneNumber) действительно ваш."
                }
            )
            .disposed(by: disposeBag)
        
        output.confirmPhoneNumber
            .drive(
                onNext: { confirmPhoneNumber in
                    self.messageLabel.text = confirmPhoneNumber
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
        
    }
    
}

