//
//  DetailGateAccessViewModel.swift
//  SmartYard
//
//  Created by Александр Попов on 18.07.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import XCoordinator
import RxSwift
import RxRelay
import RxCocoa
import Contacts

// swiftlint:disable:next type_body_length
final class DetailGateAccessViewModel: BaseViewModel {
    
    // MARK: - Properties
    
    private let router: WeakRouter<SettingsRoute>
    
    private let loadedUserContactsSubject = BehaviorSubject<[CNContact]>(value: [])
    private let addressRelay: BehaviorRelay<String?>
    private let contactsRelay = BehaviorRelay<[AllowedPerson]>(value: [])
    private let licensePlatesRelay = BehaviorRelay<[AllowedCar]>(value: [])
    private let selectedSegmentTypeRelay = BehaviorRelay<GateAccessSegmentType?>(value: nil)
    private let isLprsAvailableRelay = BehaviorRelay<Bool>(value: false)
    private let sectionModelsRelay = BehaviorRelay<[GateAccessSectionModel]>(value: [])
    private let collectionHeightRelay = BehaviorRelay<CGFloat>(value: 57)
    
    private let address: String
    private let flatId: String
    private let clientId: String?
    private let preselectedGateAccessSegmentType: GateAccessSegmentType?
    
    private let apiWrapper: APIWrapper
    private let permissionService: PermissionService
    private let logoutHelper: LogoutHelper
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
    
    private func update(carData: [AllowedCar]) {
        let footerItem = GateAccessDataItem.shortcut(.addCar)
        let licensePlaces = carData.map { GateAccessDataItem.car($0) }
        
        let sectionModel = GateAccessSectionModel(
            identity: "DetailCarSection",
            items: licensePlaces + [footerItem]
        )
        
        sectionModelsRelay.accept([sectionModel])
    }
    
    private func update(personData: [AllowedPerson]) {
        let footerItem = GateAccessDataItem.shortcut(.addPerson)
        let contacts = personData.map { GateAccessDataItem.person($0) }
        
        let sectionModel = GateAccessSectionModel(
            identity: "DetailPersonSection",
            items: contacts + [footerItem]
        )
        
        sectionModelsRelay.accept([sectionModel])
    }
    
    private func calculateCollectionViewHeight(countItems: Int) -> CGFloat {
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
    
    private func deleteAccessCar(licensePlate: AllowedCar) {
        apiWrapper
            .removeLicensePlate(
                withNumber: licensePlate.apiNumber,
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
    
    private func deleteAccessContact(person: AllowedPerson) {
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
      
    // MARK: - Public Methods
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func transform(input: Input) -> Output {
        
        // MARK: - Bindings
        
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
            .drive { [weak self] error in
                self?.router.trigger(
                    .alert(
                        title: NSLocalizedString("Error", comment: ""),
                        message: error.localizedDescription
                    )
                )
            }
            .disposed(by: disposeBag)
        
        /// Если есть доступ к контактам - сразу подгружаем данные оттуда, чтобы не тратить время потом
        if permissionService.contactsAccessStatus() == .authorized {
            loadedUserContactsSubject.onNext(getContacts())
        }
        
        ///  Загрузка изначального стейта
        let isIntercomStateLoadingFinishedSubject = BehaviorSubject<Bool>(value: false)
        
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
            .getCurrentIntercomState(flatId: flatId)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .do { _ in
                isIntercomStateLoadingFinishedSubject.onNext(true)
            }
            .ignoreNil()
            .drive { [weak self] response in
                self?.isLprsAvailableRelay.accept(!response.lprsDisabled)
            }
            .disposed(by: disposeBag)
        
        let addressDriver = apiWrapper
            .getSettingsAddresses()
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .do(onNext: { _ in
                isRoommateStateLoadingFinishedSubject.onNext(true)
            })
            .ignoreNil()
            .map { [weak self] addresses in
                addresses.first { $0.flatId == self?.flatId && $0.clientId == self?.clientId }
            }
            .ignoreNil()

        let contactsDriver = addressDriver
            .do(onNext: { [weak self] _ in
                guard let self,
                      self.permissionService.contactsAccessStatus() == .notDetermined
                else { return }

                self.permissionService.requestAccessToContacts()
                    .asDriver(onErrorJustReturn: nil)
                    .ignoreNil()
                    .drive(onNext: { [weak self] _ in
                        guard let self else { return }
                        self.loadedUserContactsSubject.onNext(self.getContacts())
                    })
                    .disposed(by: self.disposeBag)
            })
            .map { address -> [AllowedPerson] in
                address.roommates
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
            }

        contactsDriver
            .drive(contactsRelay)
            .disposed(by: disposeBag)

        isLprsAvailableRelay
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
                self?.licensePlatesRelay.accept(licensePlates)
            })
            .disposed(by: disposeBag)
        
        if preselectedGateAccessSegmentType != nil {
            self.selectedSegmentTypeRelay.accept(preselectedGateAccessSegmentType)
        }
        
        Observable
            .combineLatest(
                isInitialLoadingFinished.asObservable(),         // ждём флаг окончания первой загрузки
                contactsRelay.asObservable(),                    // текущие контакты (могут быть [])
                licensePlatesRelay.asObservable(),               // текущие номера (могут быть [])
                selectedSegmentTypeRelay.asObservable(),         // может быть nil
                isLprsAvailableRelay.asObservable()              // нужен для выбора дефолтного сегмента
            )
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isFinished, contacts, plates, selectedSegmentOpt, isLprsAvailable in
                guard let self, isFinished else { return }

                // если сегмент ещё не выбран — выбираем умно
                let selectedSegment: GateAccessSegmentType = {
                    if let segment = selectedSegmentOpt { return segment }
                    return isLprsAvailable ? .cars : .persons
                }()

                if selectedSegmentOpt == nil {
                    self.selectedSegmentTypeRelay.accept(selectedSegment)
                }

                switch selectedSegment {
                case .cars:
                    self.update(carData: plates)
                    self.collectionHeightRelay.accept(self.calculateCollectionViewHeight(countItems: plates.count))

                case .persons:
                    self.update(personData: contacts)
                    self.collectionHeightRelay.accept(self.calculateCollectionViewHeight(countItems: contacts.count))
                }
            })
            .disposed(by: disposeBag)
        
        // MARK: - Inputs
        
        input.backTrigger
            .drive(onNext: { [weak self] in
                self?.router.trigger(.back)
            })
            .disposed(by: disposeBag)
        
        input.addAccessTrigger
            .withLatestFrom(selectedSegmentTypeRelay.asDriver())
            .drive { [weak self] type in
                guard let self else { return }
                switch type {
                case .cars:
                    addNewGateAccessLicensePlate()
                    
                case .persons, .none:
                    addNewGateAccessContact()
                }
            }
            .disposed(by: disposeBag)
                
        input.segmentControlTrigger
        /// Пропускаем первый триггер, потому что может помешать предвыборному сегменту
            .skip(1)
            .distinctUntilChanged()
            .withLatestFrom(
                Driver.combineLatest(
                    contactsRelay.asDriverOnErrorJustComplete(),
                    licensePlatesRelay.asDriverOnErrorJustComplete()
                )
            ) { selectedType, data in
                (selectedType, data.0, data.1)
            }
            .drive { [weak self] type, contacts, plates in
                guard let self else { return }
                
                switch type {
                case .cars:
                    selectedSegmentTypeRelay.accept(.cars)
                    update(carData: plates)
                    collectionHeightRelay.accept(calculateCollectionViewHeight(countItems: plates.count))
                    
                case .persons:
                    selectedSegmentTypeRelay.accept(.persons)
                    update(personData: contacts)
                    collectionHeightRelay.accept(calculateCollectionViewHeight(countItems: contacts.count))
                    
                case .none:
                    break
                }
            }
            .disposed(by: disposeBag)
        
        input.smsToContactTrigger
            .flatMapLatest { [weak self] contact -> Driver<Void?> in
                guard let self else { return .empty() }
                
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
        
        input.deleteAccessContactTrigger
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
                        self?.deleteAccessContact(person: person)
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
        
        input.deleteAccessLicensePlateTrigger
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
                        self?.deleteAccessCar(licensePlate: licensePlate)
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
        
        // MARK: - Output
        
        return Output(
            objectAddress: addressRelay.asDriver(onErrorJustReturn: nil),
            selectedSegmentControlType: selectedSegmentTypeRelay.asDriver(onErrorJustReturn: nil),
            isLPRSEnabled: isLprsAvailableRelay.asDriver(onErrorJustReturn: false),
            sectionModels: sectionModelsRelay.asDriver(),
            collectionHeight: collectionHeightRelay.asDriver(),
            isInitialLoadingFinished: isInitialLoadingFinished
        )
    }
}
    
extension DetailGateAccessViewModel {
    
    struct Input {
        let segmentControlTrigger: Driver<GateAccessSegmentType?>
        let deleteAccessContactTrigger: Driver<AllowedPerson>
        let smsToContactTrigger: Driver<AllowedPerson>
        let deleteAccessLicensePlateTrigger: Driver<AllowedCar>
        let addAccessTrigger: Driver<Void>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let objectAddress: Driver<String?>
        let selectedSegmentControlType: Driver<GateAccessSegmentType?>
        let isLPRSEnabled: Driver<Bool>
        let sectionModels: Driver<[GateAccessSectionModel]>
        let collectionHeight: Driver<CGFloat>
        let isInitialLoadingFinished: Driver<Bool>
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
            .withLatestFrom(licensePlatesRelay.asDriver(onErrorJustReturn: []))
            .filter { cars in
                if cars.contains(where: { $0.apiNumber == allowedCar.apiNumber }) {
                    return false
                }
                return true
            }
            .map { cars -> [AllowedCar] in
                cars + [allowedCar]
            }
            .drive(
                onNext: { [weak self] in
                    self?.licensePlatesRelay.accept($0)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
