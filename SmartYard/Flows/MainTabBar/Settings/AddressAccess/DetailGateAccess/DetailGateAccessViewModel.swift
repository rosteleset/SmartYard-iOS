//
//  DetailGateAccessViewModel.swift
//  SmartYard
//
//  Created by Александр Попов on 18.07.2025.
//  Copyright © 2025 Sesameware. All rights reserved.
//

import XCoordinator
import RxSwift
import RxRelay
import RxCocoa
import Contacts
import RxDataSources

final class DetailGateAccessViewModel: BaseViewModel {
    
    // MARK: - Properties
    
    let router: WeakRouter<SettingsRoute>
    
    let loadedUserContactsSubject = BehaviorSubject<[CNContact]>(value: [])
    let addressRelay: BehaviorRelay<String?>
    let contactsRelay = BehaviorRelay<[AllowedPerson]>(value: [])
    let personViewStatesRelay = BehaviorRelay<[PersonViewState]>(value: [])
    let licensePlatesRelay = BehaviorRelay<[AllowedCar]>(value: [])
    let selectedSegmentTypeRelay = BehaviorRelay<GateAccessSegmentType?>(value: nil)
    let isLprsAvailableRelay = BehaviorRelay<Bool>(value: false)
    let sectionModelsRelay = BehaviorRelay<[SectionModel]>(value: [])
    let collectionHeightRelay = BehaviorRelay<CGFloat>(value: 57)
    
    let address: String
    let flatId: String
    let clientId: String?
    let preselectedGateAccessSegmentType: GateAccessSegmentType?
    
    let apiWrapper: APIWrapper
    let permissionService: PermissionService
    let logoutHelper: LogoutHelper
    private let alertService: AlertService
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
    // MARK: - Init
    
    init(
        router: WeakRouter<SettingsRoute>,
        address: String,
        flatId: String,
        clientId: String?,
        preselectedGateAccessSegmentType: GateAccessSegmentType?,
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
        self.preselectedGateAccessSegmentType = preselectedGateAccessSegmentType
        self.permissionService = permissionService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        
        addressRelay = BehaviorRelay<String?>(value: address)
        
        super.init()
    }
    
    // MARK: - Private Methods
    
    func update(carData: [AllowedCar]) {
        let footerItem = DataItem.shortcut(.addCar)
        let licensePlaces = carData.map { DataItem.car($0) }
        
        let sectionModel = SectionModel(
            identity: "DetailCarSection",
            items: licensePlaces + [footerItem]
        )
        
        sectionModelsRelay.accept([sectionModel])
    }
    
    func update(personData: [PersonViewState]) {
        let footerItem = DataItem.shortcut(.addPerson)
        let contacts = personData.map { DataItem.person($0) }
        
        let sectionModel = SectionModel(
            identity: "DetailPersonSection",
            items: contacts + [footerItem]
        )
        
        sectionModelsRelay.accept([sectionModel])
    }

    func mapPersonToViewState(_ person: AllowedPerson, now: Date = Date()) -> PersonViewState {
        let presentation = makeRemainingTimePresentation(until: person.expire, now: now)
        return PersonViewState(
            person: person,
            remainingTimeText: presentation.text,
            isExpired: presentation.isExpired
        )
    }

    private func makeRemainingTimePresentation(until expireDate: Date?, now: Date = Date()) -> RemainingTimePresentation {
        guard let expireDate else {
            return RemainingTimePresentation(
                text: L10n.Settings.AddressAccess.GateDetails.unlimited,
                isExpired: false
            )
        }

        guard expireDate > now else {
            return RemainingTimePresentation(
                text: L10n.Settings.AddressAccess.GateDetails.expired,
                isExpired: true
            )
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .short
        formatter.maximumUnitCount = 1
        formatter.zeroFormattingBehavior = .dropAll
        formatter.calendar = Calendar.current
        formatter.calendar?.locale = Locale.current

        let timeString = formatter.string(from: now, to: expireDate) ?? ""
        let format = L10n.Settings.AddressAccess.GateDetails.timeRemainingFormat
        return RemainingTimePresentation(
            text: String(format: format, timeString),
            isExpired: false
        )
    }
    
    func calculateCollectionViewHeight(countItems: Int) -> CGFloat {
        let addContactCellHeight = 57 + 16 // 16 = spacing кастомный, см. констрейнты ячейки
        let numberCellHeight = 64
        let interItemSpacing = 8
        
        let totalNumberCellsHeight = numberCellHeight * countItems
        let numberCellsSpacing = max(countItems - 1, 0) * interItemSpacing
        let spacingBeforeAddCell = countItems > 0 ? interItemSpacing : 0
        
        let totalHeight = totalNumberCellsHeight
        + numberCellsSpacing
        + spacingBeforeAddCell
        + addContactCellHeight
        
        return CGFloat(totalHeight)
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
    
    func deleteAccessCar(licensePlate: AllowedCar) {
        apiWrapper
            .removeAllowedCar(
                licensePlate,
                forFlatId: Int(flatId) ?? 0
            )
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .withLatestFrom(licensePlatesRelay.asDriver(onErrorJustReturn: []))
            .map { cars -> [AllowedCar] in
                cars.filter { $0 != licensePlate }
            }
            .drive(
                onNext: { [weak self] in
                    self?.licensePlatesRelay.accept($0)
                }
            )
            .disposed(by: disposeBag)
    }
    
    func deleteAccessContact(person: AllowedPerson) {
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
            .withLatestFrom(contactsRelay.asDriver(onErrorJustReturn: []))
            .map { contacts -> [AllowedPerson] in
                contacts.filter { $0 != person }
            }
            .drive(
                onNext: { [weak self] in
                    self?.contactsRelay.accept($0)
                    self?.apiWrapper.forceUpdateSettings = true
                }
            )
            .disposed(by: disposeBag)
    }
}
    
extension DetailGateAccessViewModel {
    
    struct Input {
        let segmentControlTrigger: Driver<GateAccessSegmentType?>
        let deleteAccessContactTrigger: Driver<AllowedPerson>
        let smsToContactTrigger: Driver<AllowedPerson>
        let editLicensePlateTrigger: Driver<AllowedCar>
        let deleteAccessLicensePlateTrigger: Driver<AllowedCar>
        let addAccessTrigger: Driver<Void>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let objectAddress: Driver<String?>
        let selectedSegmentControlType: Driver<GateAccessSegmentType?>
        let isLPRSEnabled: Driver<Bool>
        let sectionModels: Driver<[SectionModel]>
        let collectionHeight: Driver<CGFloat>
        let isInitialLoadingFinished: Driver<Bool>
    }
    
}

extension DetailGateAccessViewModel {

    struct PersonViewState: Equatable {
        let person: AllowedPerson
        let remainingTimeText: String
        let isExpired: Bool
    }

    enum DataItemIdentity: Hashable {
        case phoneNumber(String)
        case plateNumber(String)
        case shortcut
    }

    enum DataItem: IdentifiableType, Equatable {
        case car(AllowedCar)
        case person(PersonViewState)
        case shortcut(GateAccessShortcutType)

        var identity: DataItemIdentity {
            switch self {
            case .car(let car): return .plateNumber(car.identity)
            case .person(let person): return .phoneNumber(person.person.apiNumber)
            case .shortcut: return .shortcut
            }
        }

        static func == (lhs: DataItem, rhs: DataItem) -> Bool {
            switch (lhs, rhs) {
            case let (.car(lhsCar), .car(rhsCar)):
                return lhsCar == rhsCar
            case let (.person(lhsPerson), .person(rhsPerson)):
                return lhsPerson == rhsPerson
            case let (.shortcut(lhsType), .shortcut(rhsType)):
                return lhsType == rhsType
            default:
                return false
            }
        }
    }

    struct SectionModel: AnimatableSectionModelType {
        let identity: String
        var items: [DataItem]
    }

}

extension DetailGateAccessViewModel.SectionModel: SectionModelType {

    init(original: DetailGateAccessViewModel.SectionModel, items: [DetailGateAccessViewModel.DataItem]) {
        self = original
        self.items = items
    }

}

private extension DetailGateAccessViewModel {

    struct RemainingTimePresentation {
        let text: String
        let isExpired: Bool
    }

}

extension DetailGateAccessViewModel: NewAllowedPersonViewModelDelegate {
    
    func newAllowedPersonViewModelDidAddNewPermanent(
        _ viewModel: NewAllowedPersonViewModel,
        allowedPerson: AllowedPerson) {
            /// здесь пусто, так как на этом экране идет обработка только временная
        }

    /// Алерт не показывается, если мы пытаемся презентануть ошибку до того, как завершился возврат назад
    /// Он пытается презентнуть ошибку от того экрана, который мы дисмиссаем
    /// Поэтому было решено дергать dismiss отсюда, ждать завершения транзишена, а потом уже делать запрос к API
    /// Если ошибка и выскочит, то она презентнется нормально, поскольку мы уже ушли с того экрана
    
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
            .withLatestFrom(contactsRelay.asDriver(onErrorJustReturn: []))
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
                    self?.contactsRelay.accept($0)
                    self?.apiWrapper.forceUpdateSettings = true
                }
            )
            .disposed(by: disposeBag)
    }
    
}
    
extension DetailGateAccessViewModel: NewAllowedCarViewModelDelegate {
    
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
            let existing = self.licensePlatesRelay.value
            self.licensePlatesRelay.accept(result.updating(existing, original: original))
        })
    }
    
}
