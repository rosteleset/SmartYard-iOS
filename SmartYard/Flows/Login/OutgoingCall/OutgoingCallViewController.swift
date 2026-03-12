//
//  OutgoingCallViewController.swift
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

final class OutgoingCallViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var hintInputPhoneLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var fixPhoneNumberButton: UIButton!
    @IBOutlet private weak var sendCodeAgainGroupView: UIView!
    @IBOutlet private weak var numberPhoneLabel: UILabel!
    @IBOutlet private weak var containerView: TopRoundedView!
    
    @IBOutlet private var sendCodeAgainGroupButtonConstraint: NSLayoutConstraint!
    
    // swiftlint:disable all
    @IBOutlet weak var makeCallButton: BlueButton!
    @IBOutlet private weak var callPrefixLabel: UILabel!
    @IBOutlet private weak var callSuffixLabel: UILabel!
    // swiftlint:enable all

    private let copyPhoneNumberTapGesture = UITapGestureRecognizer()

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
        configureUI()
    }
    
    private func configureUI() {
        hintInputPhoneLabel.text = L10n.Auth.CallVerification.confirmPhoneTitle
        fixPhoneNumberButton.setTitle(L10n.Auth.CallVerification.editPhoneButton, for: .normal)
        makeCallButton.setTitle(L10n.Auth.CallVerification.callButton, for: .normal)
        callPrefixLabel.text = L10n.Auth.CallVerification.callInstructionPrefix
        messageLabel.text = L10n.Auth.CallVerification.phoneNumberPlaceholder
        callSuffixLabel.text = L10n.Auth.CallVerification.callInstructionSuffix
        makeCallButton.isHidden = false
        numberPhoneLabel.isUserInteractionEnabled = true

        numberPhoneLabel.addGestureRecognizer(copyPhoneNumberTapGesture)
    }
    
    private func bind() {
        let input = OutgoingCallViewModel.Input(
            fixPhoneNumberButtonTapped: fixPhoneNumberButton.rx.tap.asDriverOnErrorJustComplete(),
            backButtonTapped: fakeNavBar.rx.backButtonTap.asDriver(),
            makeCallButtonTapped: makeCallButton.rx.tap.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input: input)
        
        output.phoneNumber
            .drive(with: self) { owner, phoneNumber in
                let text = String.localizedStringWithFormat(
                    L10n.Auth.CallVerification.confirmPhoneTitleFormat,
                    "\(AccessService.shared.phonePrefix)\(phoneNumber)"
                )
                owner.hintInputPhoneLabel.text = text
            }
            .disposed(by: disposeBag)
        
        output.confirmPhoneNumber
            .drive(with: self) { owner, confirmPhoneNumber in
                owner.messageLabel.text = confirmPhoneNumber
                owner.numberPhoneLabel.text = confirmPhoneNumber
            }
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(with: self) { owner, isLoading in
                owner.updateLoader(isEnabled: isLoading, detailText: nil)
            }
            .disposed(by: disposeBag)

        copyPhoneNumberTapGesture.rx.event
            .bind(with: self, onNext: { owner, _ in
                owner.copyConfirmPhoneNumberToClipboard()
            })
            .disposed(by: disposeBag)
    }
    
    private func copyConfirmPhoneNumberToClipboard() {
        guard
            let confirmPhoneNumber = numberPhoneLabel.text,
            !confirmPhoneNumber.isEmpty
        else {
            return
        }

        UIPasteboard.general.string = confirmPhoneNumber
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
