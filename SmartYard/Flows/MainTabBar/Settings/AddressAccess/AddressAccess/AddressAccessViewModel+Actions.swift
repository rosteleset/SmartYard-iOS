// Created by Александр Попов. Copyright © 2026 Sesameware.

import Foundation
import XCoordinator
import RxSwift
import RxRelay
import RxCocoa
import Contacts

extension AddressAccessViewModel {
    func bindPermanentContactDeletion(_ input: Input) {
        input.deletePermanentContactTrigger
            .drive(
                onNext: { [weak self] index in
                    guard let self = self, let index = index else {
                        return
                    }

                    let noAction = UIAlertAction(
                        title: L10n.Common.cancel,
                        style: .cancel,
                        handler: nil
                    )

                    let yesAction = UIAlertAction(
                        title: L10n.Common.yes,
                        style: .destructive
                    ) { [weak self] _ in
                        self?.deletePermanentAccessContact(index: index)
                    }

                    self.router.trigger(
                        .dialog(
                            title: L10n.Common.Confirmation.title,
                            message: nil,
                            actions: [noAction, yesAction],
                            style: .alert
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
    }

    func bindCarDeletion(_ input: Input) {
        input.deleteGateAccessLicensePlateTrigger
            .drive(
                onNext: { [weak self] licensePlate in
                    guard let self else { return }

                    let noAction = UIAlertAction(
                        title: L10n.Common.cancel,
                        style: .cancel,
                        handler: nil
                    )

                    let yesAction = UIAlertAction(
                        title: L10n.Common.yes,
                        style: .destructive
                    ) { [weak self] _ in
                        self?.deleteGateAccessCar(licensePlate: licensePlate)
                    }

                    self.router.trigger(
                        .dialog(
                            title: L10n.Settings.AddressAccess.RemoveAccess.message,
                            message: nil,
                            actions: [noAction, yesAction],
                            style: .alert
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
    }

    func bindGateContactDeletion(_ input: Input) {
        input.deleteGateAccessContactTrigger
            .drive(
                onNext: { [weak self] person in
                    guard let self else { return }

                    let noAction = UIAlertAction(
                        title: L10n.Common.cancel,
                        style: .cancel,
                        handler: nil
                    )

                    let yesAction = UIAlertAction(
                        title: L10n.Common.yes,
                        style: .destructive
                    ) { [weak self] _ in
                        self?.deleteGateAccessContact(person: person)
                    }

                    self.router.trigger(
                        .dialog(
                            title: L10n.Settings.AddressAccess.RemoveAccess.message,
                            message: nil,
                            actions: [noAction, yesAction],
                            style: .alert
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
    }

    func bindPermanentContactSharing(_ input: Input) {
        input.smsToPermanentContactTrigger
            .withLatestFrom(permanentAccessContactsSubject.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<Void?> in
                let (index, contacts) = args

                guard let self = self, let uIndex = index, let match = contacts[safe: uIndex] else {
                    return .empty()
                }

                return self.apiWrapper
                    .resendSMS(flatId: self.flatId, guestPhone: match.apiNumber)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(
                        .dialog(
                            title: L10n.Settings.AddressAccess.GuestAccess.sentMessage,
                            message: nil,
                            actions: [
                                UIAlertAction(
                                    title: "OK",
                                    style: .default,
                                    handler: nil
                                )
                            ],
                            style: .alert
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
    }

    func bindGateContactSharing(_ input: Input) {
        input.smsToGateAccessContactTrigger
            .flatMapLatest { [weak self] contact -> Driver<Void?> in

                guard let self = self else { return .empty() }

                return self.apiWrapper
                    .resendSMS(flatId: self.flatId, guestPhone: contact.apiNumber)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(
                        .dialog(
                            title: L10n.Settings.AddressAccess.GuestAccess.sentMessage,
                            message: nil,
                            actions: [
                                UIAlertAction(
                                    title: "OK",
                                    style: .default,
                                    handler: nil
                                )
                            ],
                            style: .alert
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
    }

    func bindGateAccessDetails(_ input: Input) {
        input.goToGateAccessDetail
            .withLatestFrom(gateAccessSelectedSegmentTypeSubject.asDriver())
            .drive(
                onNext: { [weak self] type in
                    guard let self else { return }

                    self.router.trigger(
                        .detailGateAccess(
                            address: self.address,
                            flatId: self.flatId,
                            clientId: self.clientId,
                            segmentType: type
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
    }

    func toggleGuestAccess() {
        let cancelAction = UIAlertAction(
            title: L10n.Common.cancel,
            style: .cancel
        ) { _ in
            // nothing
        }

        let okAction = UIAlertAction(
            title: L10n.Common.enable,
            style: .default
        ) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.setHourGuestAccess(enabled: true)
        }

        // swiftlint:disable:next line_length
        let guestAccessAlertText = L10n.Settings.AddressAccess.GuestAccess.alertMessage

        let guestAccessAlertTitle = L10n.Settings.AddressAccess.GuestAccess.alertTitle

        guard let isGrantedIntercomGuestAccess = try? isGrantedIntercomGuestAccess.value() else {
            return
        }

        if isGrantedIntercomGuestAccess {
            setHourGuestAccess(enabled: false)
        } else {
            // enable
            router.trigger(
                .dialog(
                    title: guestAccessAlertTitle,
                    message: guestAccessAlertText,
                    actions: [cancelAction, okAction],
                    style: .alert
                )
            )
        }
    }

    private func setHourGuestAccess(enabled: Bool) {
        let response = apiWrapper.grantHourGuestAccess(
            enable: enabled,
            flatId: flatId
        )
        .trackActivity(activityTracker)
        .trackError(errorTracker)
        .asDriver(onErrorJustReturn: nil)
        .ignoreNil()

        response
            .map { $0.doorCode }
            .drive(
                onNext: { value in
                    self.intercomAccessCode.onNext(value)
                }
            )
            .disposed(by: disposeBag)

        response
            .map { response -> Bool in
                response.autoOpen > Date()
            }
            .drive(
                onNext: { value in
                    self.isGrantedIntercomGuestAccess.onNext(value)
                }
            )
            .disposed(by: disposeBag)
    }

    private func deleteGateAccessCar(licensePlate: AllowedCar) {
        apiWrapper
            .removeAllowedCar(
                licensePlate,
                forFlatId: Int(flatId) ?? 0
            )
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .withLatestFrom(gateAccessLicensePlatesSubject.asDriver(onErrorJustReturn: []))
            .map { cars -> [AllowedCar] in
                cars.filter { $0 != licensePlate }
            }
            .drive(
                onNext: { [weak self] in
                    self?.gateAccessLicensePlatesSubject.onNext($0)
                }
            )
            .disposed(by: disposeBag)
    }

    private func deleteGateAccessContact(person: AllowedPerson) {
        apiWrapper
            .revokeAccess(
                flatId: flatId,
                clientId: clientId,
                guestPhone: person.apiNumber,
                type: .outer
            )
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .withLatestFrom(gateAccessContactsSubject.asDriver(onErrorJustReturn: []))
            .map { contacts -> [AllowedPerson] in
                contacts.filter { $0 != person }
            }
            .drive(
                onNext: { [weak self] in
                    self?.gateAccessContactsSubject.onNext($0)
                    self?.apiWrapper.forceUpdateSettings = true
                }
            )
            .disposed(by: disposeBag)
    }

    private func deletePermanentAccessContact(index: Int) {
        guard
            let data = try? permanentAccessContactsSubject.value(),
            let allowedPerson = data[safe: index]
        else {
            return
        }

        apiWrapper
            .revokeAccess(
                flatId: flatId,
                clientId: clientId,
                guestPhone: allowedPerson.apiNumber,
                type: .inner
            )
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .withLatestFrom(permanentAccessContactsSubject.asDriver(onErrorJustReturn: []))
            .map { contacts -> [AllowedPerson] in
                contacts.filter { $0 != allowedPerson }
            }
            .drive(
                onNext: { [weak self] in
                    self?.permanentAccessContactsSubject.onNext($0)
                    self?.apiWrapper.forceUpdateSettings = true
                }
            )
            .disposed(by: disposeBag)
    }

    func addNewPermanentAccessContact() {
        router
            .trigger(
                .newAllowedPerson(
                    delegate: self,
                    personType: .permanent
                )
            )
    }

    func addNewGateAccessLicensePlate() {
        router
            .trigger(
                .newAllowedCar(
                    delegate: self
                )
            )
    }

    func addNewGateAccessContact() {
        router
            .trigger(
                .newAllowedPerson(
                    delegate: self,
                    personType: .temporary
                )
            )
    }
}
