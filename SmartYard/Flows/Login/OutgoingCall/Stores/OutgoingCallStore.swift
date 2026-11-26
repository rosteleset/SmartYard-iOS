//
//  OutgoingCallStore.swift
//  SmartYard
//
//  Created by Александр Попов on 26.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Observation
import RxCocoa
import RxRelay
import RxSwift
import UIKit

/// Connects the SwiftUI screen to the existing call-verification ViewModel.
@MainActor
@Observable
final class OutgoingCallStore {
    private(set) var phoneHint = L10n.Auth.CallVerification.confirmPhoneTitle
    private(set) var confirmationPhone = ""
    private(set) var isLoading = false

    @ObservationIgnored private let viewModel: OutgoingCallViewModel
    @ObservationIgnored private let fixPhoneNumberTapped = PublishRelay<Void>()
    @ObservationIgnored private let backTapped = PublishRelay<Void>()
    @ObservationIgnored private let makeCallTapped = PublishRelay<Void>()
    @ObservationIgnored private let disposeBag = DisposeBag()
    @ObservationIgnored private var hasStarted = false

    init(viewModel: OutgoingCallViewModel) {
        self.viewModel = viewModel
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        let output = viewModel.transform(
            input: OutgoingCallViewModel.Input(
                fixPhoneNumberButtonTapped: fixPhoneNumberTapped.asDriver(onErrorDriveWith: .empty()),
                backButtonTapped: backTapped.asDriver(onErrorDriveWith: .empty()),
                makeCallButtonTapped: makeCallTapped.asDriver(onErrorDriveWith: .empty())
            )
        )

        output.phoneNumber
            .drive(with: self) { owner, phoneNumber in
                MainActor.assumeIsolated {
                    owner.phoneHint = String.localizedStringWithFormat(
                        L10n.Auth.CallVerification.confirmPhoneTitleFormat,
                        AccessService.shared.phonePrefix + phoneNumber
                    )
                }
            }
            .disposed(by: disposeBag)

        output.confirmPhoneNumber
            .drive(with: self) { owner, confirmationPhone in
                MainActor.assumeIsolated { owner.confirmationPhone = confirmationPhone }
            }
            .disposed(by: disposeBag)

        output.isLoading
            .debounce(.milliseconds(25))
            .drive(with: self) { owner, isLoading in
                MainActor.assumeIsolated { owner.isLoading = isLoading }
            }
            .disposed(by: disposeBag)
    }

    func goBack() {
        backTapped.accept(())
    }

    func fixPhoneNumber() {
        fixPhoneNumberTapped.accept(())
    }

    func makeCall() {
        makeCallTapped.accept(())
    }

    func copyConfirmationPhone() {
        guard !confirmationPhone.isEmpty else { return }
        UIPasteboard.general.string = confirmationPhone
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
