//
//  InputPhoneNumberStore.swift
//  SmartYard
//
//  Created by Александр Попов on 29.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Observation
import RxCocoa
import RxRelay
import RxSwift

/// Adapts presentation and input only; authentication and routing remain in the Rx model.
@MainActor
@Observable
final class InputPhoneNumberStore {
    private(set) var phoneNumber = ""
    private(set) var providerName = L10n.Auth.PhoneEntry.providerName
    private(set) var isLoading = false
    private(set) var isPreparingTransition = false
    var wantsKeyboard = false

    let phonePrefix: String
    let digitGaps: [Bool]
    let showsProviderControls: Bool

    @ObservationIgnored private let viewModel: InputPhoneNumberViewModel
    @ObservationIgnored private let inputPhoneText = BehaviorRelay<String>(value: "")
    @ObservationIgnored private let backButtonTapped = PublishRelay<Void>()
    @ObservationIgnored private let fixProviderButtonTapped = PublishRelay<Void>()
    @ObservationIgnored private let disposeBag = DisposeBag()
    @ObservationIgnored private var hasStarted = false

    init(viewModel: InputPhoneNumberViewModel) {
        self.viewModel = viewModel
        phonePrefix = AccessService.shared.phonePrefix
        digitGaps = Self.gaps(in: AccessService.shared.phonePattern)
        showsProviderControls = Constants.defaultBackendURL.isNilOrEmpty
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        let output = viewModel.transform(
            input: InputPhoneNumberViewModel.Input(
                inputPhoneText: inputPhoneText
                    .observe(on: MainScheduler.asyncInstance)
                    .asDriver(onErrorJustReturn: ""),
                backButtonTapped: backButtonTapped.asDriver(onErrorDriveWith: .empty()),
                fixProviderButtonTapped: fixProviderButtonTapped.asDriver(onErrorDriveWith: .empty())
            )
        )

        // Driver delivery is on the main scheduler. Keep this synchronous so focus,
        // loading and the existing delayed transition retain their event ordering.
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

        output.prepareTransitionTrigger
            .drive(with: self) { owner, _ in
                MainActor.assumeIsolated {
                    owner.wantsKeyboard = false
                    owner.isPreparingTransition = true
                }
            }
            .disposed(by: disposeBag)

        output.selectedProviderName
            .drive(with: self) { owner, providerName in
                MainActor.assumeIsolated {
                    owner.providerName = providerName
                }
            }
            .disposed(by: disposeBag)
    }

    func editPhoneNumber(_ value: String) {
        // Match PhoneTextField's delegate: an overlong edit is rejected in full.
        guard value.count <= digitGaps.count, value != phoneNumber else { return }
        phoneNumber = value
        inputPhoneText.accept(value)
    }

    func beginEditing() {
        if phoneNumber.count == digitGaps.count {
            editPhoneNumber("")
        }
        wantsKeyboard = true
    }

    func didAppear() {
        wantsKeyboard = true
    }

    func willDisappear() {
        isPreparingTransition = false
        wantsKeyboard = false
    }

    func goBack() {
        backButtonTapped.accept(())
    }

    func changeProvider() {
        fixProviderButtonTapped.accept(())
    }

    private static func gaps(in pattern: String) -> [Bool] {
        var previousWasSeparator = true
        return pattern.compactMap { character in
            guard character == "#" else {
                previousWasSeparator = true
                return nil
            }
            let needsGap = previousWasSeparator
            previousWasSeparator = false
            return needsGap
        }
    }
}
