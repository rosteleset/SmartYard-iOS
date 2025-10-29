//
//  AddressAccessViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxRelay
import RxCocoa
import Contacts

// swiftlint:disable:next type_body_length
final class AddressAccessViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    
    private let loadedUserContacts = BehaviorSubject<[CNContact]>(value: [])
    private let addressSubject: BehaviorSubject<String?>
    private let permanentAccessContactsSubject = BehaviorSubject<[AllowedPerson]>(value: [])
    private let gateAccessContactsSubject = BehaviorSubject<[AllowedPerson]>(value: [])
    private let gateAccessLicensePlatesSubject = BehaviorSubject<[AllowedCar]>(value: [])
    private let gateAccessSelectedSegmentTypeSubject = BehaviorRelay<GateAccessSegmentType?>(value: nil)
    private let intercomAccessCode = BehaviorSubject<String?>(value: nil)
    private let isGrantedIntercomGuestAccess = BehaviorSubject<Bool>(value: false)
    private let isFrsAvailable = BehaviorSubject<Bool>(value: false)
    private let isLprsAvailable = BehaviorSubject<Bool>(value: false)

    private let address: String
    private let flatId: String
    private let clientId: String?
    
    private let apiWrapper: APIWrapper
    private let permissionService: PermissionService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
    init(
        router: WeakRouter<SettingsRoute>,
        address: String,
        flatId: String,
        clientId: String?,
        apiWrapper: APIWrapper,
        permissionService: PermissionService,
        logoutHelper: LogoutHelper,
        alertService: AlertService
    ) {
        self.router = router
        self.address = address
        self.flatId = flatId
        self.clientId = clientId
        self.apiWrapper = apiWrapper
        self.permissionService = permissionService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        
        addressSubject = BehaviorSubject<String?>(value: address)
        
        super.init()
    }
    
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
                            title: NSLocalizedString("Error", comment: ""),
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
                    self?.isLprsAvailable.onNext(!response.lprsDisabled)
                    self?.isFrsAvailable.onNext(!response.frsDisabled)
                    
                    let segmentType: GateAccessSegmentType = response.lprsDisabled == false ? .cars : .persons
                    self?.gateAccessSelectedSegmentTypeSubject.accept(segmentType)
                }
            )
            .disposed(by: disposeBag)
        
        /// Есть у нас права владельца или нет (от этого зависит, показываем список постоянного доступа или нет)
        let isOwnerSubject = BehaviorSubject<Bool>(value: false)
        
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

        isLprsAvailable
            .asDriver(onErrorJustReturn: false)
            .distinctUntilChanged()
            .flatMapLatest { [weak self] available -> Driver<[AllowedCar]> in
                guard let self = self else { return .empty() }

                if available {
                    let id = Int(self.flatId) ?? -1 // тут значение 100% будет
                    return self.apiWrapper.getLicensePlates(forFlatId: id)
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
                        .do(
                            onNext: { _ in
                                isGateStateLoadingFinishedSubject.onNext(true)
                            }
                        )
                        .map { data -> [AllowedCar] in
                            guard let data, !data.isEmpty else { return [] }
                            return data.map { AllowedCar(rawNumber: $0) }
                        }
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
            .drive(
                onNext: { [weak self] in
                    guard
                        let self = self,
                        let flatId = Int(self.flatId)
                    else {
                        return
                    }
                    
                    self.router.trigger(
                        .facesSettings(
                            flatId: flatId,
                            address: self.address
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
        
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
                            title: NSLocalizedString("Guest information has been successfully sent!", comment: ""),
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
                            title: NSLocalizedString("Guest information has been successfully sent!", comment: ""),
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
        
        input.deleteGateAccessContactTrigger
            .drive(
                onNext: { [weak self] person in
                    guard let self else { return }
                    
                    let noAction = UIAlertAction(
                        title: NSLocalizedString("Cancel", comment: ""),
                        style: .cancel,
                        handler: nil
                    )
                    
                    let yesAction = UIAlertAction(
                        title: NSLocalizedString("Yes", comment: ""),
                        style: .destructive
                    ) { [weak self] _ in
                        self?.deleteGateAccessContact(person: person)
                    }
                    
                    self.router.trigger(
                        .dialog(
                            title: NSLocalizedString("Do you want to remove access?", comment: ""),
                            message: nil,
                            actions: [noAction, yesAction],
                            style: .alert
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
        
        input.deleteGateAccessLicensePlateTrigger
            .drive(
                onNext: { [weak self] licensePlate in
                    guard let self else { return }
                    
                    let noAction = UIAlertAction(
                        title: NSLocalizedString("Cancel", comment: ""),
                        style: .cancel,
                        handler: nil
                    )
                    
                    let yesAction = UIAlertAction(
                        title: NSLocalizedString("Yes", comment: ""),
                        style: .destructive
                    ) { [weak self] _ in
                        self?.deleteGateAccessCar(licensePlate: licensePlate)
                    }
                    
                    self.router.trigger(
                        .dialog(
                            title: NSLocalizedString("Do you want to remove access?", comment: ""),
                            message: nil,
                            actions: [noAction, yesAction],
                            style: .alert
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
        
        input.deletePermanentContactTrigger
            .drive(
                onNext: { [weak self] index in
                    guard let self = self, let index = index else {
                        return
                    }
                    
                    let noAction = UIAlertAction(
                        title: NSLocalizedString("Cancel", comment: ""),
                        style: .cancel,
                        handler: nil
                    )
                    
                    let yesAction = UIAlertAction(
                        title: NSLocalizedString("Yes", comment: ""),
                        style: .destructive
                    ) { [weak self] _ in
                        self?.deletePermanentAccessContact(index: index)
                    }
                    
                    self.router.trigger(
                        .dialog(
                            title: NSLocalizedString("Are you sure?", comment: ""),
                            message: nil,
                            actions: [noAction, yesAction],
                            style: .alert
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
        
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
    
    private func toggleGuestAccess() {
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel
        ) { _ in
            // nothing
        }
        
        let okAction = UIAlertAction(
            title: NSLocalizedString("Enable", comment: ""),
            style: .default
        ) { [weak self] _ in
            guard let self = self else {
                return
            }
            
            let response = self.apiWrapper.grantHourGuestAccess(
                enable: true,
                flatId: self.flatId
            )
            .trackActivity(self.activityTracker)
            .trackError(self.errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            
            response
                .map { $0.doorCode }
                .drive(
                    onNext: { value in
                        self.intercomAccessCode.onNext(value)
                    }
                )
                .disposed(by: self.disposeBag)
            
            response
                .map { response -> Bool in
                    response.autoOpen > Date()
                }
                .drive(
                    onNext: { value in
                        self.isGrantedIntercomGuestAccess.onNext(value)
                    }
                )
                .disposed(by: self.disposeBag)
        }
        
        // swiftlint:disable:next line_length
        let guestAccessAlertText = NSLocalizedString("guestAccessAlertText", comment: "")
        
        let guestAccessAlertTitle = NSLocalizedString("Enable guest access for an hour?", comment: "")
        
        guard let isGrantedIntercomGuestAccess = try? isGrantedIntercomGuestAccess.value() else {
            return
        }
        
        if isGrantedIntercomGuestAccess {
            // disable
            let response = apiWrapper.grantHourGuestAccess(
                enable: false,
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
    
    private func deleteGateAccessCar(licensePlate: AllowedCar) {
        apiWrapper
            .removeLicensePlate(
                withNumber: licensePlate.apiNumber,
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
    
    private func addNewPermanentAccessContact() {
        router
            .trigger(
                .newAllowedPerson(
                    delegate: self,
                    personType: .permanent
                )
            )
    }
    
    private func addNewGateAccessLicensePlate() {
        router
            .trigger(
                .newAllowedCar(
                    delegate: self
                )
            )
    }
    
    private func addNewGateAccessContact() {
        router
            .trigger(
                .newAllowedPerson(
                    delegate: self,
                    personType: .temporary
                )
            )
    }
    
}

extension AddressAccessViewModel {
    
    struct Input {
        let viewDidAppearTrigger: Driver<Bool>
        let refreshIntercomTempCodeTrigger: Driver<Void>
        let openGuestAccessTrigger: Driver<Void>
        let waitingGuestsHintTrigger: Driver<Void>
        let configureFaces: Driver<Void>
        let segmentControlTrigger: Driver<GateAccessSegmentType?>
        let smsToPermanentContactTrigger: Driver<Int?>
        let smsToGateAccessContactTrigger: Driver<AllowedPerson>
        let deletePermanentContactTrigger: Driver<Int?>
        let deleteGateAccessContactTrigger: Driver<AllowedPerson>
        let deleteGateAccessLicensePlateTrigger: Driver<AllowedCar>
        let addNewPermanentContact: Driver<Void>
        let addNewGateAccessContact: Driver<Void>
        let addNewGateAccessLicensePlate: Driver<Void>
        let goToGateAccessDetail: Driver<Void>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let objectAddress: Driver<String?>
        let gateAccessContacts: Driver<[AllowedPerson]>
        let gateAccessLicensePlates: Driver<[AllowedCar]>
        let gateAccessSelectedSegmentControlType: Driver<GateAccessSegmentType?>
        let permanentAccessContacts: Driver<[AllowedPerson]>
        let temporaryIntercomCode: Driver<String?>
        let isGrantedIntercomAccess: Driver<Bool>
        let isLoading: Driver<Bool>
        let isFRSEnabled: Driver<Bool>
        let isLPRSEnabled: Driver<Bool>
        let hasGates: Driver<Bool>
        let isOwner: Driver<Bool>
        let isInitialLoadingFinished: Driver<Bool>
    }
    
}

extension AddressAccessViewModel: NewAllowedPersonViewModelDelegate {
    
    // MARK: алерт не показывается, если мы пытаемся презентануть ошибку до того, как завершился возврат назад
    // Он пытается презентнуть ошибку от того экрана, который мы дисмиссаем
    // Поэтому было решено дергать dismiss отсюда, ждать завершения транзишена, а потом уже делать запрос к API
    // Если ошибка и выскочит, то она презентнется нормально, поскольку мы уже ушли с того экрана
    
    func newAllowedPersonViewModelDidAddNewTemp(
        _ viewModel: NewAllowedPersonViewModel,
        allowedPerson: AllowedPerson
    ) {
        router.rx
            .trigger(.dismiss)
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return apiWrapper
                    .grantAccess(
                        flatId: flatId,
                        guestPhone: allowedPerson.apiNumber,
                        type: .outer
                    )
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .withLatestFrom(gateAccessContactsSubject.asDriver(onErrorJustReturn: []))
            .filter { contacts in
                if contacts.contains(where: { $0.apiNumber == allowedPerson.apiNumber }) {
                    return false
                }
                return true
            }
            .map { contacts -> [AllowedPerson] in
                contacts + [allowedPerson]
            }
            .drive(
                onNext: { [weak self] in
                    self?.gateAccessContactsSubject.onNext($0)
                    self?.apiWrapper.forceUpdateSettings = true
                }
            )
            .disposed(by: disposeBag)
    }
    
    func newAllowedPersonViewModelDidAddNewPermanent(
        _ viewModel: NewAllowedPersonViewModel,
        allowedPerson: AllowedPerson
    ) {
        router.rx
            .trigger(.dismiss)
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return apiWrapper
                    .grantAccess(
                        flatId: flatId,
                        guestPhone: allowedPerson.apiNumber,
                        type: .inner
                    )
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .withLatestFrom(permanentAccessContactsSubject.asDriver(onErrorJustReturn: []))
            .filter { contacts in
                if contacts.contains(where: { $0.apiNumber == allowedPerson.apiNumber }) {
                    return false
                }
                return true
            }
            .map { contacts -> [AllowedPerson] in
                contacts + [allowedPerson]
            }
            .drive(
                onNext: { [weak self] in
                    self?.permanentAccessContactsSubject.onNext($0)
                    self?.apiWrapper.forceUpdateSettings = true
                }
            )
            .disposed(by: disposeBag)
    }

}

extension AddressAccessViewModel: NewAllowedCarViewModelDelegate {
    
    func newAllowedCarViewModelDidAdd(
        _ viewModel: NewAllowedCarViewModel,
        allowedCar: AllowedCar
    ) {
        router.rx
            .trigger(.dismiss)
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                                
                return apiWrapper
                    .addLicensePlate(
                        withNumber: allowedCar.apiNumber,
                        forFlatId: Int(flatId) ?? -1
                    )
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .withLatestFrom(gateAccessLicensePlatesSubject.asDriver(onErrorJustReturn: []))
            .filter { cars in
                if cars.contains(where: { $0.apiNumber == allowedCar.apiNumber }) {
                    return false
                }
                return true
            }
            .map { cars -> [AllowedCar] in
                [allowedCar] + cars 
            }
            .drive(
                onNext: { [weak self] in
                    self?.gateAccessLicensePlatesSubject.onNext($0)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
// swiftlint:disable:next file_length
