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

class AddressAccessViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    
    private let addressSubject = PublishSubject<String?>()
    private let tempAccessConstactsSubject = BehaviorSubject<[AllowedPerson]>(value: [])
    private let permanentAccessContactsSubject = BehaviorSubject<[AllowedPerson]>(value: [])
    private let intercomAccessCode = PublishSubject<String?>()
    private let isGrantedIntercomGuestAccess = PublishSubject<Bool>()
    
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
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        loadData()
        
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
                    self?.intercomAccessCode.onNext(result.code)
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
        
        return Output(
            objectAddress: addressSubject.asDriver(onErrorJustReturn: ""),
            tempAccessContacts: tempAccessConstactsSubject.asDriver(onErrorJustReturn: []),
            permanentAccessContacts: permanentAccessContactsSubject.asDriver(onErrorJustReturn: []),
            temporaryIntercomCode: intercomAccessCode,
            isGrantedIntercomAccess: isGrantedIntercomGuestAccess,
            isLoading: activityTracker.asDriver()
        )
    }
    
    private func loadData() {
        self.addressSubject.onNext(address)
        self.tempAccessConstactsSubject.onNext(self.loadTemporaryAccessContacts())
        self.permanentAccessContactsSubject.onNext(self.loadPermanentAccessContacts())
    }
    
    private func loadTemporaryAccessContacts() -> [AllowedPerson] {
        return [
            AllowedPerson(displayedName: nil, phoneNumber: "+7 (903) 343-17-40", logoImage: nil),
            AllowedPerson(displayedName: nil, phoneNumber: "+7 (902) 741-82-90", logoImage: nil),
            AllowedPerson(displayedName: nil, phoneNumber: "+7 (903) 944-47-50", logoImage: nil)
        ]
    }
    
    private func loadPermanentAccessContacts() -> [AllowedPerson] {
        return []
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
        guard let data = try? tempAccessConstactsSubject.value() else {
            return
        }
        
        var newData = data
        newData.remove(at: index)
        
        tempAccessConstactsSubject.onNext(newData)
        // TODO: use API deletion method
    }
    
    private func deletePermanentAccessContact(index: Int) {
        guard let data = try? permanentAccessContactsSubject.value() else {
            return
        }
        
        var newData = data
        newData.remove(at: index)
        
        permanentAccessContactsSubject.onNext(newData)
        // TODO: use API deletion method
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
        let temporaryIntercomCode: PublishSubject<String?>
        let isGrantedIntercomAccess: PublishSubject<Bool>
        let isLoading: Driver<Bool>
    }
    
}

extension AddressAccessViewModel: NewAllowedPersonViewModelDelegate {
    
    func newAllowedPersonViewModelDidAddNewTemp(
        _ viewModel: NewAllowedPersonViewModel,
        allowedPerson: AllowedPerson
    ) {
        guard let data = try? tempAccessConstactsSubject.value() else {
            return
        }
        
        var newData = data
        newData.append(allowedPerson)
        tempAccessConstactsSubject.onNext(newData)
        // TODO: save data, using api
    }
    
    func newAllowedPersonViewModelDidAddNewPermanent(
        _ viewModel: NewAllowedPersonViewModel,
        allowedPerson: AllowedPerson
    ) {
        guard let data = try? permanentAccessContactsSubject.value() else {
            return
        }
        
        var newData = data
        newData.append(allowedPerson)
        permanentAccessContactsSubject.onNext(newData)
        // TODO: save data, using api
    }

}
