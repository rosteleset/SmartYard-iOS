//
//  AddressAccessViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxRelay
import RxCocoa
import Contacts

final class AddressAccessViewModel: BaseViewModel {
    
    let router: WeakRouter<SettingsRoute>

    let loadedUserContacts = BehaviorSubject<[CNContact]>(value: [])
    let addressSubject: BehaviorSubject<String?>
    let permanentAccessContactsSubject = BehaviorSubject<[AllowedPerson]>(value: [])
    let gateAccessContactsSubject = BehaviorSubject<[AllowedPerson]>(value: [])
    let gateAccessLicensePlatesSubject = BehaviorSubject<[AllowedCar]>(value: [])
    let gateAccessSelectedSegmentTypeSubject = BehaviorRelay<GateAccessSegmentType?>(value: nil)
    let intercomAccessCode = BehaviorSubject<String?>(value: nil)
    let isGrantedIntercomGuestAccess = BehaviorSubject<Bool>(value: false)
    let isFrsAvailable = BehaviorSubject<Bool>(value: false)
    let isLprsAvailable = BehaviorSubject<Bool>(value: false)

    let address: String
    let flatId: String
    let clientId: String?

    let apiWrapper: APIWrapper
    let permissionService: PermissionService
    let logoutHelper: LogoutHelper
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
        let editLicensePlateTrigger: Driver<AllowedCar>
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
    
    func newAllowedCarViewModel(
        _ viewModel: NewAllowedCarViewModel,
        save car: AllowedCar,
        trackingEnabled: Bool,
        replacing original: AllowedCar?
    ) -> Single<LicensePlateSaveResult> {
        apiWrapper.saveAllowedCar(
            car, trackingEnabled: trackingEnabled, replacing: original, flatId: Int(flatId) ?? -1
        )
        .observe(on: MainScheduler.instance)
        .do(onSuccess: { [weak self] result in
            guard let self else { return }
            let existing = (try? self.gateAccessLicensePlatesSubject.value()) ?? []
            self.gateAccessLicensePlatesSubject.onNext(result.updating(existing, original: original))
        })
    }
    
}
