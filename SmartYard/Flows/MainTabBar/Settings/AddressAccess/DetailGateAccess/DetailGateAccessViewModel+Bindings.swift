// Created by Александр Попов. Copyright © 2026 Sesameware.

import XCoordinator
import RxSwift
import RxRelay
import RxCocoa
import Contacts
import RxDataSources

extension DetailGateAccessViewModel {
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
                        title: L10n.Common.error,
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
                self?.isLprsAvailableRelay.accept(!(response.lprsDisabled ?? true))
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

        let minuteTicker = Observable<Int>
            .interval(.seconds(60), scheduler: MainScheduler.instance)
            .startWith(0)
            .asDriver(onErrorJustReturn: 0)

        Driver
            .combineLatest(
                contactsRelay.asDriver(onErrorJustReturn: []),
                minuteTicker
            )
            .map { [weak self] persons, _ -> [PersonViewState] in
                guard let self else { return [] }
                let now = Date()
                return persons.map { self.mapPersonToViewState($0, now: now) }
            }
            .drive(personViewStatesRelay)
            .disposed(by: disposeBag)

        isLprsAvailableRelay
            .asDriver(onErrorJustReturn: false)
            .distinctUntilChanged()
            .flatMapLatest { [weak self] available -> Driver<[AllowedCar]> in
                guard let self = self else { return .empty() }

                if available {
                    let id = Int(self.flatId) ?? -1 // тут значение 100% будет
                    return self.apiWrapper.getAllowedCars(forFlatId: id)
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: [])
                        .do(
                            onNext: { _ in
                                isGateStateLoadingFinishedSubject.onNext(true)
                            }
                        )
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
                personViewStatesRelay.asObservable(),            // текущие контакты (могут быть [])
                licensePlatesRelay.asObservable(),               // текущие номера (могут быть [])
                selectedSegmentTypeRelay.asObservable(),         // может быть nil
                isLprsAvailableRelay.asObservable()              // нужен для выбора дефолтного сегмента
            )
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isFinished, personViewStates, plates, selectedSegmentOpt, isLprsAvailable in
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
                    self.update(personData: personViewStates)
                    self.collectionHeightRelay.accept(self.calculateCollectionViewHeight(countItems: personViewStates.count))
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
                    personViewStatesRelay.asDriverOnErrorJustComplete(),
                    licensePlatesRelay.asDriverOnErrorJustComplete()
                )
            ) { selectedType, data in
                (selectedType, data.0, data.1)
            }
            .drive { [weak self] type, personViewStates, plates in
                guard let self else { return }

                switch type {
                case .cars:
                    selectedSegmentTypeRelay.accept(.cars)
                    update(carData: plates)
                    collectionHeightRelay.accept(calculateCollectionViewHeight(countItems: plates.count))

                case .persons:
                    selectedSegmentTypeRelay.accept(.persons)
                    update(personData: personViewStates)
                    collectionHeightRelay.accept(calculateCollectionViewHeight(countItems: personViewStates.count))

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
                            title: L10n.Settings.AddressAccess.GuestAccess.sentMessage,
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
                        title: L10n.Common.cancel,
                        style: .cancel,
                        handler: nil
                    )

                    let yesAction = UIAlertAction(
                        title: L10n.Common.yes,
                        style: .destructive
                    ) { [weak self] _ in
                        self?.deleteAccessContact(person: person)
                    }

                    self.router.trigger(
                        .dialog(
                            title: L10n.Settings.AddressAccess.RemoveAccess.message,
                            message: nil,
                            actions: [noAction, yesAction],
                            style: .alert
                        )
                    )
                }
            )
            .disposed(by: disposeBag)

        input.editLicensePlateTrigger
            .drive(with: self) { owner, car in
                owner.router.trigger(.newAllowedCar(delegate: owner, car: car))
            }
            .disposed(by: disposeBag)

        input.deleteAccessLicensePlateTrigger
            .drive(
                onNext: { [weak self] licensePlate in
                    guard let self else { return }

                    let noAction = UIAlertAction(
                        title: L10n.Common.cancel,
                        style: .cancel,
                        handler: nil
                    )

                    let yesAction = UIAlertAction(
                        title: L10n.Common.yes,
                        style: .destructive
                    ) { [weak self] _ in
                        self?.deleteAccessCar(licensePlate: licensePlate)
                    }

                    self.router.trigger(
                        .dialog(
                            title: L10n.Settings.AddressAccess.RemoveAccess.message,
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
