//
//  PinCodeStore.swift
//  SmartYard
//
//  Created by Александр Попов on 29.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation
import Observation
import RxCocoa
import RxRelay
import RxSwift

/// Presents the existing Rx authentication flow and manages the resend countdown.
@MainActor
@Observable
final class PinCodeStore {
    private(set) var pin = ""
    private(set) var phoneHint = L10n.Auth.SMSCode.sentToPhoneTitle
    private(set) var isPinCorrect = true
    private(set) var isLoading = false
    private(set) var isPreparingTransition = false
    private(set) var isResendAvailable: Bool
    private(set) var remainingSeconds = 0
    var wantsKeyboard = false

    var countdownText: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    @ObservationIgnored private let viewModel: PinCodeViewModel
    @ObservationIgnored private let isInitial: Bool
    @ObservationIgnored private let useFlashCall: Bool
    @ObservationIgnored private let phonePrefix: String
    @ObservationIgnored private let inputPinText = BehaviorRelay<String>(value: "")
    @ObservationIgnored private let fixPhoneNumberButtonTapped = PublishRelay<Void>()
    @ObservationIgnored private let backButtonTapped = PublishRelay<Void>()
    @ObservationIgnored private let sendCodeAgainButtonTapped = PublishRelay<Void>()
    @ObservationIgnored private let disposeBag = DisposeBag()
    @ObservationIgnored private var countdownBag = DisposeBag()
    @ObservationIgnored private var countdownDeadline: Date?
    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private var isVisible = false

    init(viewModel: PinCodeViewModel, isInitial: Bool, useFlashCall: Bool, phonePrefix: String) {
        self.viewModel = viewModel
        self.isInitial = isInitial
        self.useFlashCall = useFlashCall
        self.phonePrefix = phonePrefix
        isResendAvailable = !isInitial
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        let output = viewModel.transform(
            input: PinCodeViewModel.Input(
                inputPinText: inputPinText
                    .observe(on: MainScheduler.asyncInstance)
                    .asDriver(onErrorJustReturn: ""),
                fixPhoneNumberButtonTapped: fixPhoneNumberButtonTapped.asDriver(onErrorDriveWith: .empty()),
                backButtonTapped: backButtonTapped.asDriver(onErrorDriveWith: .empty()),
                sendCodeAgainButtonTapped: sendCodeAgainButtonTapped.asDriver(onErrorDriveWith: .empty())
            )
        )
        bindPresentation(output)
        bindLoading(output)

        if isInitial {
            startCountdown()
        }
    }

    func editPin(_ value: String) {
        guard value.count <= Constants.pinLength, value != pin else { return }
        pin = value
        inputPinText.accept(value)
    }

    func fixPhoneNumber() {
        fixPhoneNumberButtonTapped.accept(())
    }

    func goBack() {
        backButtonTapped.accept(())
    }

    func resendCode() {
        guard isResendAvailable else { return }
        // Start the countdown as soon as the user taps resend.
        startCountdown()
        sendCodeAgainButtonTapped.accept(())
    }

    func didAppear() {
        isVisible = true
        wantsKeyboard = true
        resumeCountdown()
    }

    func willDisappear() {
        isVisible = false
        wantsKeyboard = false
        isPreparingTransition = false
        countdownBag = DisposeBag()
    }

    private func bindPresentation(_ output: PinCodeViewModel.Output) {
        // Drivers deliver on the main scheduler, keeping presentation changes in order.
        output.phoneNumber
            .drive(with: self) { owner, phoneNumber in
                MainActor.assumeIsolated {
                    let format = owner.useFlashCall ? L10n.Auth.FlashCall.enterLastDigitsTitleFormat
                        : L10n.Auth.SMSCode.sentToPhoneTitleFormat
                    owner.phoneHint = String.localizedStringWithFormat(format, owner.phonePrefix + phoneNumber)
                }
            }
            .disposed(by: disposeBag)

        output.isPinCorrect
            .drive(with: self) { owner, isCorrect in
                MainActor.assumeIsolated { owner.isPinCorrect = isCorrect }
            }
            .disposed(by: disposeBag)

        output.prepareTransitionTrigger
            .drive(with: self) { owner, _ in
                MainActor.assumeIsolated {
                    owner.wantsKeyboard = false
                    owner.isPreparingTransition = true
                }
            }
            .disposed(by: disposeBag)
    }

    private func bindLoading(_ output: PinCodeViewModel.Output) {
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(with: self) { owner, isLoading in
                MainActor.assumeIsolated {
                    owner.isLoading = isLoading
                    if isLoading {
                        owner.wantsKeyboard = false
                    }
                }
            }
            .disposed(by: disposeBag)
    }

    private func startCountdown() {
        countdownDeadline = Date().addingTimeInterval(60)
        isResendAvailable = false
        updateCountdown()
        resumeCountdown()
    }

    private func resumeCountdown() {
        countdownBag = DisposeBag()
        guard isVisible, countdownDeadline != nil else { return }
        updateCountdown()
        guard !isResendAvailable else { return }

        Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(with: self) { owner, _ in
                MainActor.assumeIsolated { owner.updateCountdown() }
            }
            .disposed(by: countdownBag)
    }

    private func updateCountdown() {
        guard let countdownDeadline else { return }
        let interval = countdownDeadline.timeIntervalSinceNow
        remainingSeconds = max(0, Int(interval))
        guard interval <= 0 else { return }
        self.countdownDeadline = nil
        isResendAvailable = true
        countdownBag = DisposeBag()
    }
}
