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
    
    private let address: String
    
    init(router: WeakRouter<SettingsRoute>, address: String) {
        self.router = router
        self.address = address
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        loadData()
        
        input.refreshIntercomTempCodeTrigger
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.intercomAccessCode.onNext(self.loadIntercomAccessCode())
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
                    self.deleteTempAccessContact(index: index)
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
            permanentAccessContacts: permanentAccessContactsSubject.asDriver(onErrorJustReturn: [])
        )
    }
    
    private func loadData() {
        self.addressSubject.onNext(address)
        self.tempAccessConstactsSubject.onNext(self.loadTemporaryAccessContacts())
        self.permanentAccessContactsSubject.onNext(self.loadPermanentAccessContacts())
        self.intercomAccessCode.onNext(self.loadIntercomAccessCode())
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
    
    private func loadIntercomAccessCode() -> String {
        return "5432"
    }
    
    private func openGuestAccess() {
        print("Open guest access!")
        // TODO
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
