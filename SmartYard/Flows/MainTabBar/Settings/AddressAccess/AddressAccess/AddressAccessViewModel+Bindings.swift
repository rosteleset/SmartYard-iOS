// Created by Александр Попов. Copyright © 2026 Sesameware.

import Foundation
import XCoordinator
import RxSwift
import RxRelay
import RxCocoa
import Contacts

extension AddressAccessViewModel {
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        errorTracker.asDriver()
            .catchAuthorizationError { [weak self] in
                guard let self = self else {
                    return
                }

                self.logoutHelper.showAuthErrorAlert(
                    activityTracker: activityTracker,
                    errorTracker: errorTracker,
                    disposeBag: disposeBag
                )
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(
                        .alert(
                            title: L10n.Common.error,
                            message: error.localizedDescription
                        )
                    )
                }
            )
            .disposed(by: disposeBag)

        /// Если есть доступ к контактам - сразу подгружаем данные оттуда, чтобы не тратить время потом
        if permissionService.contactsAccessStatus() == .authorized {
            loadedUserContacts.onNext(getContacts())
        }

        // MARK: Загрузка изначального стейта

        let isIntercomStateLoadingFinishedSubject = BehaviorSubject<Bool>(value: false)

        apiWrapper
            .getCurrentIntercomState(flatId: flatId)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .do(
                onNext: { _ in
                    isIntercomStateLoadingFinishedSubject.onNext(true)
                }
            )
            .ignoreNil()
            .drive(
                onNext: { [weak self] response in
                    self?.intercomAccessCode.onNext(response.doorCode)

                    let isAccessGranted = response.autoOpen > Date()

                    self?.isGrantedIntercomGuestAccess.onNext(isAccessGranted)

                    let lpsrAvailable = (!(response.lprsDisabled ?? true))
                    let frsAvailable = (!(response.frsDisabled ?? true))

                    self?.isLprsAvailable.onNext(lpsrAvailable)
                    self?.isFrsAvailable.onNext(frsAvailable)

                    let segmentType: GateAccessSegmentType = response.lprsDisabled == false ? .cars : .persons
                    self?.gateAccessSelectedSegmentTypeSubject.accept(segmentType)
                }
            )
            .disposed(by: disposeBag)

        /// Есть у нас права владельца или нет (от этого зависит, показываем список постоянного доступа или нет)
        let isOwnerSubject = BehaviorSubject<Bool>(value: false)

        /// Есть ли у пользователя доступ к журналу событий, из которого можно добавить лицо
        let hasPlogSubject = BehaviorSubject<Bool>(value: false)

        /// Есть ли в доме ворота/калитки
        /// От этого зависит, показываем список временного доступа и доступ для автомобилей или нет
        let hasGatesSubject = BehaviorSubject<Bool>(value: false)

        /// Загрузка номеров, которым предоставлен доступ
        let isRoommateStateLoadingFinishedSubject = BehaviorSubject<Bool>(value: false)

        /// Загрузка номеров машины, которым предоставлен доступ
        let isGateStateLoadingFinishedSubject = BehaviorSubject<Bool>(value: false)

        let isInitialLoadingFinished = Driver
            .combineLatest(
                isIntercomStateLoadingFinishedSubject.asDriver(onErrorJustReturn: false),
                isRoommateStateLoadingFinishedSubject.asDriver(onErrorJustReturn: false),
                isGateStateLoadingFinishedSubject.asDriver(onErrorJustReturn: false)
            )
            .map { args -> Bool in
                let (intercomState, roommateState, gateState) = args

                return intercomState && roommateState && gateState
            }

        apiWrapper
            .getSettingsAddresses()
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .do(
                onNext: { _ in
                    isRoommateStateLoadingFinishedSubject.onNext(true)
                }
            )
            .ignoreNil()
            .map { [weak self] addresses in
                addresses.first { $0.flatId == self?.flatId && $0.clientId == self?.clientId }
            }
            .ignoreNil()
            .do(
                onNext: { [weak self] address in
                    let isOwner = (address.flatOwner ?? false) || (address.contractOwner ?? false)
                    let hasGates = address.hasGates ?? false

                    isOwnerSubject.onNext(isOwner)
                    hasGatesSubject.onNext(hasGates)
                    hasPlogSubject.onNext(address.hasPlog)

                    // MARK: Здесь нужно запросить доступ к контактам при выполнении условий:
                    // 1. Юзер может раздавать временный или постоянный доступ (иначе нет смысла)
                    // 2. Статус доступа - .notDetermined (еще не запрашивали)

                    guard
                        let self = self,
                        isOwner || hasGates,
                        self.permissionService.contactsAccessStatus() == .notDetermined
                    else {
                        return
                    }

                    self.permissionService.requestAccessToContacts()
                        .asDriver(onErrorJustReturn: nil)
                        .ignoreNil()
                        .drive(
                            onNext: { [weak self] in
                                guard let self = self else {
                                    return
                                }

                                self.loadedUserContacts.onNext(self.getContacts())
                            }
                        )
                        .disposed(by: self.disposeBag)
                }
            )
            .map { address -> ([AllowedPerson], [AllowedPerson]) in
                let gateAccessRoommates: [AllowedPerson] = address.roommates
                    .filter { $0.type == .outer && $0.expire > Date() }
                    .compactMap { roommate in
                        guard let rawNumber = roommate.phone.rawPhoneNumberFromFullNumber else {
                            return nil
                        }

                        return AllowedPerson(
                            roommateType: roommate.type,
                            displayedName: nil,
                            rawNumber: rawNumber,
                            logoImage: nil,
                            expire: roommate.expire
                        )
                    }

                let permanentAccessRoommates: [AllowedPerson] = address.roommates
                    .filter { ($0.type == .inner || $0.type == .owner) && $0.expire > Date() }
                    .compactMap { roommate in
                        guard let rawNumber = roommate.phone.rawPhoneNumberFromFullNumber else {
                            return nil
                        }

                        return AllowedPerson(
                            roommateType: roommate.type,
                            displayedName: nil,
                            rawNumber: rawNumber,
                            logoImage: nil,
                            expire: nil
                        )
                    }

                return (gateAccessRoommates, permanentAccessRoommates)
            }
            .drive(
                onNext: { [weak self] roommates in
                    let (temp, permanent) = roommates
                    self?.gateAccessContactsSubject.onNext(temp)
                    self?.permanentAccessContactsSubject.onNext(permanent)
                }
            )
            .disposed(by: disposeBag)

        Driver.merge(
            isLprsAvailable.asDriver(onErrorJustReturn: false).distinctUntilChanged(),
            input.viewDidAppearTrigger.skip(1)
                .withLatestFrom(isLprsAvailable.asDriver(onErrorJustReturn: false))
        )
            .flatMapLatest { [weak self] available -> Driver<[AllowedCar]> in
                guard let self = self else { return .empty() }

                if available {
                    let id = Int(self.flatId) ?? -1 // тут значение 100% будет
                    return self.apiWrapper.getAllowedCars(forFlatId: id)
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: [])
                        .do(
                            onNext: { _ in
                                isGateStateLoadingFinishedSubject.onNext(true)
                            }
                        )
                } else {
                    isGateStateLoadingFinishedSubject.onNext(true)
                    return .just([])
                }
            }
            .drive(onNext: { [weak self] licensePlates in
                self?.gateAccessLicensePlatesSubject.onNext(licensePlates)
            })
            .disposed(by: disposeBag)

        input.refreshIntercomTempCodeTrigger
            .asDriver()
            .debounce(.milliseconds(25))
            .flatMapLatest { [weak self] _ -> Driver<ResetCodeResponseData?> in
                guard let self = self else { return .empty() }

                return self.apiWrapper.resetCode(flatId: self.flatId)
                    .trackError(self.errorTracker)
                    .trackActivity(self.activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] result in
                    self?.intercomAccessCode.onNext(result.code.string)
                }
            )
            .disposed(by: disposeBag)

        input.openGuestAccessTrigger
            .drive(
                onNext: { [weak self] in
                    self?.toggleGuestAccess()
                }
            )
            .disposed(by: disposeBag)

        input.waitingGuestsHintTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.showModal(withContent: .aboutWaitingGuests))
                }
            )
            .disposed(by: disposeBag)

        input.configureFaces
            .withLatestFrom(hasPlogSubject.asDriver(onErrorJustReturn: false))
            .drive(with: self) { owner, hasPlog in
                guard let flatId = Int(owner.flatId) else {
                    return
                }

                owner.router.trigger(
                    .facesSettings(
                        flatId: flatId,
                        address: owner.address,
                        canAddFace: hasPlog
                    )
                )
            }
            .disposed(by: disposeBag)

        bindGateContactSharing(input)

        bindPermanentContactSharing(input)

        bindGateContactDeletion(input)

        input.editLicensePlateTrigger
            .drive(with: self) { owner, car in
                owner.router.trigger(.newAllowedCar(delegate: owner, car: car))
            }
            .disposed(by: disposeBag)

        bindCarDeletion(input)

        bindPermanentContactDeletion(input)

        input.addNewGateAccessContact
            .withLatestFrom(gateAccessSelectedSegmentTypeSubject.asDriver())
            .filter { $0 == .persons }
            .mapToVoid()
            .drive(
                onNext: { [weak self] in
                    self?.addNewGateAccessContact()
                }
            )
            .disposed(by: disposeBag)

        input.addNewGateAccessLicensePlate
            .withLatestFrom(gateAccessSelectedSegmentTypeSubject.asDriver())
            .filter { $0 == .cars }
            .mapToVoid()
            .drive(onNext: { [weak self] in
                self?.addNewGateAccessLicensePlate()
            })
            .disposed(by: disposeBag)

        bindGateAccessDetails(input)

        input.segmentControlTrigger
            .distinctUntilChanged()
            .drive(onNext: { [weak self] type in
                self?.gateAccessSelectedSegmentTypeSubject.accept(type)
            })
            .disposed(by: disposeBag)

        input.addNewPermanentContact
            .drive(
                onNext: { [weak self] in
                    self?.addNewPermanentAccessContact()
                }
            )
            .disposed(by: disposeBag)

        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)

        let formattedTempContacts = Driver
            .combineLatest(
                gateAccessContactsSubject.asDriver(onErrorJustReturn: []),
                loadedUserContacts.asDriver(onErrorJustReturn: [])
            )
            .map { [weak self] args -> [AllowedPerson] in
                let (contactsWithAccess, localContactList) = args

                return self?.fillAllowedPersonsWithContactData(
                    contactsWithAccess,
                    contactList: localContactList
                ) ?? []
            }

        let formattedPermanentContacts = Driver
            .combineLatest(
                permanentAccessContactsSubject.asDriver(onErrorJustReturn: []),
                loadedUserContacts.asDriver(onErrorJustReturn: [])
            )
            .map { [weak self] args -> [AllowedPerson] in
                let (contactsWithAccess, localContactList) = args

                return self?.fillAllowedPersonsWithContactData(
                    contactsWithAccess,
                    contactList: localContactList
                ) ?? []
            }

        return Output(
            objectAddress: addressSubject.asDriver(onErrorJustReturn: nil),
            gateAccessContacts: formattedTempContacts,
            gateAccessLicensePlates: gateAccessLicensePlatesSubject.asDriver(onErrorJustReturn: []),
            gateAccessSelectedSegmentControlType: gateAccessSelectedSegmentTypeSubject.asDriver(),
            permanentAccessContacts: formattedPermanentContacts,
            temporaryIntercomCode: intercomAccessCode.asDriver(onErrorJustReturn: nil),
            isGrantedIntercomAccess: isGrantedIntercomGuestAccess.asDriver(onErrorJustReturn: false),
            isLoading: activityTracker.asDriver(),
            isFRSEnabled: isFrsAvailable.asDriver(onErrorJustReturn: false),
            isLPRSEnabled: isLprsAvailable.asDriver(onErrorJustReturn: false),
            hasGates: hasGatesSubject.asDriver(onErrorJustReturn: false),
            isOwner: isOwnerSubject.asDriver(onErrorJustReturn: false),
            isInitialLoadingFinished: isInitialLoadingFinished
        )
    }
}
