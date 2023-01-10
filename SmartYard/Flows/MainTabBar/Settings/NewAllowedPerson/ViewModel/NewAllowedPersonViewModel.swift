//
//  NewAllowedPersonViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 17.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import Contacts

protocol NewAllowedPersonViewModelDelegate: AnyObject {
    
    func newAllowedPersonViewModelDidAddNewTemp(
        _ viewModel: NewAllowedPersonViewModel,
        allowedPerson: AllowedPerson
    )
    
    func newAllowedPersonViewModelDidAddNewPermanent(
        _ viewModel: NewAllowedPersonViewModel,
        allowedPerson: AllowedPerson
    )
    
}

class NewAllowedPersonViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    private let allowedPersonType: AllowedPersonType

    private let latestAddedPerson = BehaviorSubject<AllowedPerson?>(value: nil)
    
    private weak var delegate: NewAllowedPersonViewModelDelegate?
    
    init(
        router: WeakRouter<SettingsRoute>,
        delegate: NewAllowedPersonViewModelDelegate,
        allowedPersonType: AllowedPersonType
    ) {
        self.router = router
        self.allowedPersonType = allowedPersonType
        self.delegate = delegate
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        input.closeTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Маппинг обычных введенных номеров
        
        input.rawPhoneAddedTrigger
            .distinctUntilChanged()
            .map { [weak self] phoneText -> AllowedPerson? in
                guard let self = self, !phoneText.isEmpty else {
                    return nil
                }
                
                let phoneCharsArray = phoneText.components(separatedBy: CharacterSet.alphanumerics.inverted)
                
                let cleanPhone = String(phoneCharsArray.joined(separator: "").dropFirst())
                
                guard cleanPhone.count == AccessService.shared.phoneLengthWithoutPrefix else {
                    return nil
                }
                
                return AllowedPerson(
                    roommateType: self.allowedPersonType == .temporary ? .outer : .inner,
                    displayedName: nil,
                    rawNumber: cleanPhone,
                    logoImage: nil
                )
            }
            .drive(
                onNext: { [weak self] person in
                    self?.latestAddedPerson.onNext(person)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Маппинг добавленных контактов
        
        let importedPerson = BehaviorSubject<AllowedPerson?>(value: nil)
        
        input.cnContactAddedTrigger
            .map { [weak self] contact, phoneIndex in
                guard let self = self,
                      (0 ... contact.phoneNumbers.count - 1) ~= phoneIndex,
                      let rawNumber = contact.phoneNumbers[phoneIndex].value.stringValue.rawPhoneNumberFromFullNumber
                else { return nil }
                
                let nameToShow: String? = {
                    let joinedName = [contact.givenName, contact.familyName]
                        .joined(separator: " ")
                        .trimmed
                    
                    return joinedName.isEmpty ? nil : joinedName
                }()

                let icon: UIImage? = {
                    if contact.imageDataAvailable, let imageData = contact.thumbnailImageData {
                        return UIImage(data: imageData)
                    } else {
                        return nil
                    }
                }()
                
                let allowedPerson = AllowedPerson(
                    roommateType: self.allowedPersonType == .temporary ? .outer : .inner,
                    displayedName: nameToShow,
                    rawNumber: rawNumber,
                    logoImage: icon
                )

                return allowedPerson
            }
            .do(
                onNext: { person in
                    importedPerson.onNext(person)
                }
            )
            .drive(
                onNext: { [weak self] person in
                    self?.latestAddedPerson.onNext(person)
                }
            )
            .disposed(by: disposeBag)
        
        let personWasSuccessfullyImported = importedPerson
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
        
        let isAbleToProceed = latestAddedPerson
            .asDriver(onErrorJustReturn: nil)
            .map { person -> Bool in
                person?.rawNumber.count == AccessService.shared.phoneLengthWithoutPrefix
            }

        input.addAccessTrigger
            .withLatestFrom(latestAddedPerson.asDriver(onErrorJustReturn: nil))
            .ignoreNil()
            .drive(
                onNext: { [weak self] person in
                    guard let self = self else {
                        return
                    }
                    
                    switch self.allowedPersonType {
                    case .permanent:
                        self.delegate?.newAllowedPersonViewModelDidAddNewPermanent(
                            self,
                            allowedPerson: person
                        )
                        
                    case .temporary:
                        self.delegate?.newAllowedPersonViewModelDidAddNewTemp(
                            self,
                            allowedPerson: person
                        )
                    }
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isAbleToProceed: isAbleToProceed,
            personWasSuccessfullyImported: personWasSuccessfullyImported
        )
    }
    
}

extension NewAllowedPersonViewModel {
    
    struct Input {
        let closeTrigger: Driver<Void>
        let rawPhoneAddedTrigger: Driver<String>
        let cnContactAddedTrigger: Driver<(CNContact,Int)>
        let addAccessTrigger: Driver<Void>
    }
    
    struct Output {
        let isAbleToProceed: Driver<Bool>
        let personWasSuccessfullyImported: Driver<AllowedPerson>
    }
    
}
