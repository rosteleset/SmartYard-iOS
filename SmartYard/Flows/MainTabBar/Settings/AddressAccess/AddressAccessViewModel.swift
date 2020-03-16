//
//  AddressAccessViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa

// swiftlint:disable:next type_body_length
class AddressAccessViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    
    private let addressSubject: BehaviorSubject<String?>
    private let tempAccessContactsSubject = BehaviorSubject<[AllowedPerson]>(value: [])
    private let permanentAccessContactsSubject = BehaviorSubject<[AllowedPerson]>(value: [])
    private let intercomAccessCode = BehaviorSubject<String?>(value: nil)
    private let isGrantedIntercomGuestAccess = BehaviorSubject<Bool>(value: false)
    
    private let address: String
    private let flatId: String
    
    private let apiWrapper: APIWrapper
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
    init(router: WeakRouter<SettingsRoute>, address: String, flatId: String, apiWrapper: APIWrapper) {
        self.router = router
        self.address = address
        self.flatId = flatId
        self.apiWrapper = apiWrapper
        
        addressSubject = BehaviorSubject<String?>(value: address)
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
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
                    
                    let isAccessGranted: Bool = {
                        guard let dateUntilClose = response.autoOpen.dateFromAPIString else {
                            return false
                        }
                        
                        return dateUntilClose > Date()
                    }()
                    
                    self?.isGrantedIntercomGuestAccess.onNext(isAccessGranted)
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
                addresses.first { $0.flatId == self?.flatId }
            }
            .ignoreNil()
            .do(
                onNext: { address in
                    isOwnerSubject.onNext((address.flatOwner ?? false) || (address.contractOwner ?? false))
                    hasGatesSubject.onNext(address.hasGates ?? false)
                }
            )
            .map { address -> ([AllowedPerson], [AllowedPerson]) in
                let tempAccessRoommates: [AllowedPerson] = address.roommates
                    .filter { $0.type == .outer && $0.expire > Date() }
                    .compactMap { roommate in
                        guard let rawNumber = roommate.phone.rawPhoneNumberFromFullNumber else {
                            return nil
                        }
                        
                        return AllowedPerson(displayedName: nil, rawNumber: rawNumber, logoImage: nil)
                    }
                
                let permanentAccessRoommates: [AllowedPerson] = address.roommates
                    .filter { ($0.type == .inner || $0.type == .owner) && $0.expire > Date() }
                    .compactMap { roommate in
                        guard let rawNumber = roommate.phone.rawPhoneNumberFromFullNumber else {
                            return nil
                        }
                        
                        return AllowedPerson(displayedName: nil, rawNumber: rawNumber, logoImage: nil)
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
        
        input.smsToTempContactTrigger
            .drive(
                onNext: { [weak self] index in
                    guard let self = self, let index = index else {
                        return
                    }
                    
                    self.sendSmsToTemporaryAccessContact(index: index)
                }
            )
            .disposed(by: disposeBag)
        
        input.smsToPermanentContactTrigger
            .drive(
                onNext: { [weak self] index in
                    guard let self = self, let index = index else {
                        return
                    }
                    
                    self.sendSmsToPermanentAccessContact(index: index)
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
                    
                    self.deletePermanentAccessContact(index: index)
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
        
        errorTracker.asDriver()
            .drive(
                onNext: { error in
                    print(error)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            objectAddress: addressSubject.asDriver(onErrorJustReturn: nil),
            tempAccessContacts: tempAccessContactsSubject.asDriver(onErrorJustReturn: []),
            permanentAccessContacts: permanentAccessContactsSubject.asDriver(onErrorJustReturn: []),
            temporaryIntercomCode: intercomAccessCode.asDriver(onErrorJustReturn: nil),
            isGrantedIntercomAccess: isGrantedIntercomGuestAccess.asDriver(onErrorJustReturn: false),
            isLoading: activityTracker.asDriver(),
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
                    guard let dateUntilClose = response.autoOpen.dateFromAPIString else {
                        return false
                    }
                    
                    return dateUntilClose > Date()
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
    
    private func sendSmsToTemporaryAccessContact(index: Int) {
        print("SEND SMS TO USER WITH INDEX: \(index)")
        sendSMS(number: "+7-908-474-27-41")
    }
    
    private func sendSmsToPermanentAccessContact(index: Int) {
        print("SEND SMS TO USER WITH INDEX: \(index)")
        sendSMS(number: "+7-908-474-27-41")
    }
    
    private func sendSMS(number: String) {
        // TODO
    }
    
    private func deleteTempAccessContact(index: Int) {
        guard let data = try? tempAccessContactsSubject.value(), let allowedPerson = data[safe: index] else {
            return
        }
        
        apiWrapper
            .revokeAccess(flatId: flatId, guestPhone: allowedPerson.apiNumber, type: .outer)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: {
                    print("Actually, that number was removed")
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func deletePermanentAccessContact(index: Int) {
        guard let data = try? permanentAccessContactsSubject.value(), let allowedPerson = data[safe: index] else {
            return
        }
        
        apiWrapper
            .revokeAccess(flatId: flatId, guestPhone: allowedPerson.apiNumber, type: .inner)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: {
                    print("Actually, that number was removed")
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
        let hasGates: Driver<Bool>
        let isOwner: Driver<Bool>
        let isInitialLoadingFinished: Driver<Bool>
    }
    
}

extension AddressAccessViewModel: NewAllowedPersonViewModelDelegate {
    
    func newAllowedPersonViewModelDidAddNewTemp(
        _ viewModel: NewAllowedPersonViewModel,
        allowedPerson: AllowedPerson
    ) {
        apiWrapper
            .grantAccess(flatId: flatId, guestPhone: allowedPerson.apiNumber, type: .outer)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: {
                    print("Actually, new number was added")
                }
            )
            .disposed(by: disposeBag)
    }
    
    func newAllowedPersonViewModelDidAddNewPermanent(
        _ viewModel: NewAllowedPersonViewModel,
        allowedPerson: AllowedPerson
    ) {
        apiWrapper
            .grantAccess(flatId: flatId, guestPhone: allowedPerson.apiNumber, type: .inner)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: {
                    print("Actually, new number was added")
                }
            )
            .disposed(by: disposeBag)
    }

// swiftlint:disable:next file_length
}
