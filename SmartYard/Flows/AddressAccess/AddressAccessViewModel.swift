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
    
    private let router: WeakRouter<AppRoute>
    
    let addressSubject = PublishSubject<String?>()
    let tempAccessConstactsSubject = PublishSubject<[AllowedPerson]>()
    let permanentAccessContactSubject = PublishSubject<[AllowedPerson]>()
    let intercomAccessCode = PublishSubject<String?>()
    
    init(
        router: WeakRouter<AppRoute>) {
        self.router = router
    }
    
    func transform(input: Input) -> Output {
        input.viewDidAppearTrigger
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
            print("viewDidAppearTrigger!!!")
                    self.addressSubject.onNext(self.loadAddress())
                    self.tempAccessConstactsSubject.onNext(self.loadTemporaryAccessContacts())
                    self.permanentAccessContactSubject.onNext(self.loadPermanentAccessContacts())
                    self.intercomAccessCode.onNext(self.loadIntercomAccessCode())
                    
                }
            )
            .disposed(by: disposeBag)
        
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
        
        return Output(
            objectAddress: addressSubject.asDriver(onErrorJustReturn: ""),
            tempAccessContacts: tempAccessConstactsSubject.asDriver(onErrorJustReturn: []),
            permanentAccessContacts: permanentAccessContactSubject.asDriver(onErrorJustReturn: [])
        )
    }
    
    // TODO: load real data
    private func loadAddress() -> String {
        return "г.Ульяновск, ул. Верхнеполевая, д.12, кв.6"
    }
    
    private func loadTemporaryAccessContacts() -> [AllowedPerson] {
        return [
            AllowedPerson(displayedName: "Вася", phoneNumber: "+7-903-343-17-40", logoImage: nil),
            AllowedPerson(displayedName: "Петя", phoneNumber: "+7-902-741-82-90", logoImage: nil),
            AllowedPerson(displayedName: "Коля", phoneNumber: "+7-903-944-47-50", logoImage: nil)
        ]
    }
    
    private func loadPermanentAccessContacts() -> [AllowedPerson] {
        return []
    }
    
    private func loadIntercomAccessCode() -> String {
        return "5432"
    }
    
    private func openGuestAccess() {
        // TODO
    }
    
    private func sendSmsToTemporaryAccessContact(index: Int) {
        sendSMS(number: "+7-908-474-27-41")
    }
    
    private func sendSmsToPermanentAccessContact(index: Int) {
        sendSMS(number: "+7-908-474-27-41")
    }
    
    private func sendSMS(number: String) {
        // TODO
    }
    
    private func deleteTempAccessContact(index: Int) {
        // TODO
    }
    
    private func deletePermanentAccessContact(index: Int) {
        // TODO
    }
    
    private func addNewTempAccessContact() {
        // TODO
    }
    
    private func addNewPermanentAccessContact() {
        // TODO
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
    }
    
    struct Output {
        let objectAddress: Driver<String?>
        let tempAccessContacts: Driver<[AllowedPerson]>
        let permanentAccessContacts: Driver<[AllowedPerson]>
    }
    
}
