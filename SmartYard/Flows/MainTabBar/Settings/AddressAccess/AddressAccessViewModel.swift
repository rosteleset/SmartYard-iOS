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
import RxCocoa
import Contacts

// swiftlint:disable:next type_body_length
class AddressAccessViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    
    private let loadedUserContacts = BehaviorSubject<[CNContact]>(value: [])
    private let addressSubject: BehaviorSubject<String?>
    private let tempAccessContactsSubject = BehaviorSubject<[AllowedPerson]>(value: [])
    private let permanentAccessContactsSubject = BehaviorSubject<[AllowedPerson]>(value: [])
    private let intercomAccessCode = BehaviorSubject<String?>(value: nil)
    private let isGrantedIntercomGuestAccess = BehaviorSubject<Bool>(value: false)
    private let isFrsAvailable = BehaviorSubject<Bool?>(value: nil)
    
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
                    activityTracker: self.activityTracker,
                    errorTracker: self.errorTracker,
                    disposeBag: self.disposeBag
                )
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Если есть доступ к контактам - сразу подгружаем данные оттуда, чтобы не тратить время потом
        
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
                    
                    if let isFrsNotAvailable = response.frsDisabled {
                        self?.isFrsAvailable.onNext(!isFrsNotAvailable)
                    } else {
                        self?.isFrsAvailable.onNext(nil)
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Есть у нас права владельца или нет (от этого зависит, показываем список постоянного доступа или нет)
        
        let isOwnerSubject = BehaviorSubject<Bool>(value: false)
        
        // MARK: Есть ли в доме ворота / калитки (от этого зависит, показываем список временного доступа или нет)
        
        let hasGatesSubject = BehaviorSubject<Bool>(value: false)
        
        // MARK: Загрузка номеров, которым предоставлен доступ
        
        let isRoommateStateLoadingFinishedSubject = BehaviorSubject<Bool>(value: false)
        
        let isInitialLoadingFinished = Driver
            .combineLatest(
                isIntercomStateLoadingFinishedSubject.asDriver(onErrorJustReturn: false),
                isRoommateStateLoadingFinishedSubject.asDriver(onErrorJustReturn: false)
            )
            .map { args -> Bool in
                let (intercomState, roommateState) = args
                
                return intercomState && roommateState
            }
        
        self.apiWrapper
            .getSettingsAddresses()
            .trackError(self.errorTracker)
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
                    
                    guard let self = self,
                        (isOwner || hasGates),
                        self.permissionService.contactsAccessStatus() == .notDetermined else {
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
                let tempAccessRoommates: [AllowedPerson] = address.roommates
                    .filter { $0.type == .outer && $0.expire > Date() }
                    .compactMap { roommate in
                        guard let rawNumber = roommate.phone.rawPhoneNumberFromFullNumber else {
                            return nil
                        }
                        
                        return AllowedPerson(
                            roommateType: roommate.type,
                            displayedName: nil,
                            rawNumber: rawNumber,
                            logoImage: nil
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
                            logoImage: nil
                        )
                    }
                
                return (tempAccessRoommates, permanentAccessRoommates)
            }
            .drive(
                onNext: { [weak self] roommates in
                    let (temp, permanent) = roommates
                    
                    self?.tempAccessContactsSubject.onNext(temp)
                    self?.permanentAccessContactsSubject.onNext(permanent)
                }
            )
            .disposed(by: disposeBag)
        
        input.refreshIntercomTempCodeTrigger
            .asDriver()
            .debounce(.milliseconds(25))
            .flatMapLatest { [weak self] _ -> Driver<ResetCodeResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
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
                    self?.openGuestAccess()
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
                    guard let self = self,
                          let flatId = Int(self.flatId) else {
                        return
                    }
                    
                    self.router.trigger(.facesSettings(flatId: flatId, address: self.address))
                }
            )
            .disposed(by: disposeBag)
        
        input.smsToTempContactTrigger
            .withLatestFrom(tempAccessContactsSubject.asDriver(onErrorJustReturn: [])) { ($0, $1) }
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
                            title: "Информация для гостя успешно отправлена!",
                            message: nil,
                            actions: [UIAlertAction(title: "OK", style: .default, handler: nil)]
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
                            title: "Информация для гостя успешно отправлена!",
                            message: nil,
                            actions: [UIAlertAction(title: "OK", style: .default, handler: nil)]
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
        
        input.deleteTempContactTrigger
            .drive(
                onNext: { [weak self] index in
                    guard let self = self, let index = index else {
                        return
                    }
                    
                    let noAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
                    
                    let yesAction = UIAlertAction(title: "Да", style: .destructive) { [weak self] _ in
                        self?.deleteTempAccessContact(index: index)
                    }
                    
                    self.router.trigger(.dialog(title: "Вы уверены?", message: nil, actions: [noAction, yesAction]))
                }
            )
            .disposed(by: disposeBag)
        
        input.deletePermanentContactTrigger
            .drive(
                onNext: { [weak self] index in
                    guard let self = self, let index = index else {
                        return
                    }
                    
                    let noAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
                    
                    let yesAction = UIAlertAction(title: "Да", style: .destructive) { [weak self] _ in
                        self?.deletePermanentAccessContact(index: index)
                    }
                    
                    self.router.trigger(.dialog(title: "Вы уверены?", message: nil, actions: [noAction, yesAction]))
                }
            )
            .disposed(by: disposeBag)
        
        input.addNewTempContact
            .drive(
                onNext: { [weak self] in
                    self?.addNewTempAccessContact()
                }
            )
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
                tempAccessContactsSubject.asDriver(onErrorJustReturn: []),
                loadedUserContacts.asDriver(onErrorJustReturn: [])
            )
            .map { [weak self] args -> [AllowedPerson] in
                let (contactsWithAccess, localContactList) = args
                
                return self?.fillAllowedPersonsWithContactData(contactsWithAccess, contactList: localContactList) ?? []
            }
        
        let formattedPermanentContacts = Driver
            .combineLatest(
                permanentAccessContactsSubject.asDriver(onErrorJustReturn: []),
                loadedUserContacts.asDriver(onErrorJustReturn: [])
            )
            .map { [weak self] args -> [AllowedPerson] in
                let (contactsWithAccess, localContactList) = args
                
                return self?.fillAllowedPersonsWithContactData(contactsWithAccess, contactList: localContactList) ?? []
            }
        
        return Output(
            objectAddress: addressSubject.asDriver(onErrorJustReturn: nil),
            tempAccessContacts: formattedTempContacts,
            permanentAccessContacts: formattedPermanentContacts,
            temporaryIntercomCode: intercomAccessCode.asDriver(onErrorJustReturn: nil),
            isGrantedIntercomAccess: isGrantedIntercomGuestAccess.asDriver(onErrorJustReturn: false),
            isLoading: activityTracker.asDriver(),
            isFRSEnabled: isFrsAvailable.asDriver(onErrorJustReturn: nil),
            hasGates: hasGatesSubject.asDriver(onErrorJustReturn: false),
            isOwner: isOwnerSubject.asDriver(onErrorJustReturn: false),
            isInitialLoadingFinished: isInitialLoadingFinished
        )
    }
    
    private func openGuestAccess() {
        let cancelAction = UIAlertAction(
            title: "Отмена",
            style: .cancel
        ) { _ in
            // nothing
        }
        
        let okAction = UIAlertAction(
            title: "Включить",
            style: .default
        ) { [weak self] _ in
            guard let self = self else {
                return
            }
            
            let response = self.apiWrapper.grantHourGuestAccess(flatId: self.flatId)
                .trackActivity(self.activityTracker)
                .trackError(self.errorTracker)
                .asDriver(onErrorJustReturn: nil)
                .ignoreNil()
            
            response
                .map { $0.doorCode }
                .drive(self.intercomAccessCode)
                .disposed(by: self.disposeBag)
            
            response
                .map { response -> Bool in
                    response.autoOpen > Date()
                }
                .drive(self.isGrantedIntercomGuestAccess)
                .disposed(by: self.disposeBag)
        }
        
        // swiftlint:disable:next line_length
        let guestAccessAlertText = "Всем, кто будет набирать номер вашей квартиры на домофоне, дверь будет открываться автоматически в течение 60 минут. По истечению данного времени работа домофона вернется в стандартный режим автоматически."
        
        let guestAccessAlertTitle = "Включить гостевой доступ на час?"
        
        self.router.trigger(
            .dialog(
                title: guestAccessAlertTitle,
                message: guestAccessAlertText,
                actions: [cancelAction, okAction]
            )
        )
    }
    
    private func deleteTempAccessContact(index: Int) {
        guard let data = try? tempAccessContactsSubject.value(), let allowedPerson = data[safe: index] else {
            return
        }
        
        apiWrapper
            .revokeAccess(flatId: flatId, clientId: clientId, guestPhone: allowedPerson.apiNumber, type: .outer)
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .withLatestFrom(tempAccessContactsSubject.asDriver(onErrorJustReturn: []))
            .map { contacts -> [AllowedPerson] in
                contacts.filter { $0 != allowedPerson }
            }
            .drive(
                onNext: { [weak self] in
                    self?.tempAccessContactsSubject.onNext($0)
                    self?.apiWrapper.forceUpdateSettings = true
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func deletePermanentAccessContact(index: Int) {
        guard let data = try? permanentAccessContactsSubject.value(), let allowedPerson = data[safe: index] else {
            return
        }
        
        apiWrapper
            .revokeAccess(flatId: flatId, clientId: clientId, guestPhone: allowedPerson.apiNumber, type: .inner)
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
    
    private func addNewTempAccessContact() {
        self.router
            .trigger(
                .newAllowedPerson(
                    delegate: self,
                    personType: .temporary
                )
            )
    }
    
    private func addNewPermanentAccessContact() {
        self.router
            .trigger(
                .newAllowedPerson(
                    delegate: self,
                    personType: .permanent
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
        let smsToTempContactTrigger: Driver<Int?>
        let smsToPermanentContactTrigger: Driver<Int?>
        let deleteTempContactTrigger: Driver<Int?>
        let deletePermanentContactTrigger: Driver<Int?>
        let addNewTempContact: Driver<Void>
        let addNewPermanentContact: Driver<Void>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let objectAddress: Driver<String?>
        let tempAccessContacts: Driver<[AllowedPerson]>
        let permanentAccessContacts: Driver<[AllowedPerson]>
        let temporaryIntercomCode: Driver<String?>
        let isGrantedIntercomAccess: Driver<Bool>
        let isLoading: Driver<Bool>
        let isFRSEnabled: Driver<Bool?>
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
                
                return self.apiWrapper
                    .grantAccess(flatId: self.flatId, guestPhone: allowedPerson.apiNumber, type: .outer)
                    .trackError(self.errorTracker)
                    .trackActivity(self.activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .withLatestFrom(tempAccessContactsSubject.asDriver(onErrorJustReturn: []))
            .map { contacts -> [AllowedPerson] in
                contacts + [allowedPerson]
            }
            .drive(
                onNext: { [weak self] in
                    self?.tempAccessContactsSubject.onNext($0)
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
                
                return self.apiWrapper
                    .grantAccess(flatId: self.flatId, guestPhone: allowedPerson.apiNumber, type: .inner)
                    .trackError(self.errorTracker)
                    .trackActivity(self.activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .withLatestFrom(permanentAccessContactsSubject.asDriver(onErrorJustReturn: []))
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

// swiftlint:disable:next file_length
}
