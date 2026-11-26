//
//  UserNameStore.swift
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

@MainActor
@Observable
final class UserNameStore {
    private(set) var name: String
    private(set) var middleName: String
    private(set) var isNameValid: Bool
    private(set) var isMiddleNameValid: Bool
    private(set) var agreement: NSAttributedString?
    private(set) var isAgreementAccepted = false
    private(set) var isContinueEnabled = false
    private(set) var isLoading = false
    private(set) var isPreparingTransition = false

    @ObservationIgnored private let viewModel: UserNameViewModel
    @ObservationIgnored private let nameValidator: NamePartValidator
    @ObservationIgnored private let middleNameValidator: NamePartValidator
    @ObservationIgnored private let nameInput: BehaviorRelay<String?>
    @ObservationIgnored private let middleNameInput: BehaviorRelay<String?>
    @ObservationIgnored private let nameValidityInput: BehaviorRelay<Bool>
    @ObservationIgnored private let middleNameValidityInput: BehaviorRelay<Bool>
    @ObservationIgnored private let agreementInput = BehaviorRelay(value: false)
    @ObservationIgnored private let legalDocumentTrigger = PublishRelay<URL>()
    @ObservationIgnored private let continueTrigger = PublishRelay<Void>()
    @ObservationIgnored private let disposeBag = DisposeBag()
    @ObservationIgnored private var hasStarted = false

    init(viewModel: UserNameViewModel, preloadedName: APIClientName?) {
        self.viewModel = viewModel
        let pattern = AccessService.shared.nameValidationPattern
        let nameValidator = ValidatorFactory.makeFirst(from: pattern)
        let middleNameValidator = ValidatorFactory.makePatronymic(from: pattern)
        self.nameValidator = nameValidator
        self.middleNameValidator = middleNameValidator

        let name = preloadedName?.name ?? ""
        let middleName = preloadedName?.patronymic ?? ""
        let isNameValid = nameValidator.validate(name)
        let isMiddleNameValid = middleNameValidator.validate(middleName)
        self.name = name
        self.middleName = middleName
        self.isNameValid = isNameValid
        self.isMiddleNameValid = isMiddleNameValid
        nameInput = BehaviorRelay(value: preloadedName?.name)
        middleNameInput = BehaviorRelay(value: preloadedName?.patronymic)
        nameValidityInput = BehaviorRelay(value: isNameValid)
        middleNameValidityInput = BehaviorRelay(value: isMiddleNameValid)
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        let output = viewModel.transform(
            input: UserNameViewModel.Input(
                name: nameInput.asDriver(),
                middleName: middleNameInput.asDriver(),
                isNameValid: nameValidityInput.asDriver(),
                isMiddleNameValid: middleNameValidityInput.asDriver(),
                isAgreementAccepted: agreementInput.asDriver(),
                legalDocumentTrigger: legalDocumentTrigger.asDriver(onErrorDriveWith: .empty()),
                continueTrigger: continueTrigger.asDriver(onErrorDriveWith: .empty())
            )
        )

        output.isLoading
            .debounce(.milliseconds(25))
            .drive(with: self) { owner, isLoading in
                MainActor.assumeIsolated { owner.isLoading = isLoading }
            }
            .disposed(by: disposeBag)

        output.prepareTransitionTrigger
            .drive(with: self) { owner, _ in
                MainActor.assumeIsolated { owner.isPreparingTransition = true }
            }
            .disposed(by: disposeBag)

        output.agreementHTML
            .drive(with: self) { owner, html in
                MainActor.assumeIsolated { owner.updateAgreement(serverHTML: html) }
            }
            .disposed(by: disposeBag)

        output.isContinueEnabled
            .drive(with: self) { owner, isEnabled in
                MainActor.assumeIsolated { owner.isContinueEnabled = isEnabled }
            }
            .disposed(by: disposeBag)
    }

    func editName(_ value: String) {
        name = value
        isNameValid = nameValidator.validate(value)
        nameInput.accept(value)
        nameValidityInput.accept(isNameValid)
    }

    func editMiddleName(_ value: String) {
        middleName = value
        isMiddleNameValid = middleNameValidator.validate(value)
        middleNameInput.accept(value)
        middleNameValidityInput.accept(isMiddleNameValid)
    }

    func toggleAgreement() {
        guard agreement != nil else { return }
        isAgreementAccepted.toggle()
        agreementInput.accept(isAgreementAccepted)
    }

    func openLegalDocument(_ url: URL) {
        legalDocumentTrigger.accept(url)
    }

    func continueToMain() {
        guard isContinueEnabled, !isLoading, !isPreparingTransition else { return }
        continueTrigger.accept(())
    }

    func willDisappear() {
        isPreparingTransition = false
    }

    private func updateAgreement(serverHTML: String?) {
        agreement = UserNameAgreement.caption(serverHTML: serverHTML)
        if agreement == nil {
            isAgreementAccepted = true
            agreementInput.accept(true)
        }
    }
}
