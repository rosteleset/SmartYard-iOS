//
//  AddressesViewModel.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class AddressesListViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let pushNotificationService: PushNotificationService
    private let router: WeakRouter<HomeRoute>
    
    init(
        apiWrapper: APIWrapper,
        pushNotificationService: PushNotificationService,
        router: WeakRouter<HomeRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.pushNotificationService = pushNotificationService
        self.router = router
    }
    
    private let loadedData = BehaviorSubject<GetAddressListResponseData?>(value: nil)
    
    // MARK: Словарь необходим для того, чтобы хранить состояния раскрытости секций
    private let areSectionsExpanded = BehaviorSubject<[String: Bool]>(value: [:])
    // MARK: Словарь необходим для того, чтобы хранить состояния предоставленного доступа к объекту
    private let areObjectsGrantAccessed = BehaviorSubject<[AddressesListDataItemIdentity: Bool]>(value: [:])
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        // MARK: Подписка на уведомления
        
        pushNotificationService.registerForPushNotifications()
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: {
                    print("DEBUG: Successfully subscribed to push notifications")
                }
            )
            .disposed(by: disposeBag)
        
        let isInitialLoadingFinishedSubject = BehaviorSubject<Bool>(value: false)
        let isInitialLoadingFinished = isInitialLoadingFinishedSubject.asDriver(onErrorJustReturn: false)
        
        let reloadingFinishedSubject = PublishSubject<Void>()
        let reloadingFinished = reloadingFinishedSubject.asDriverOnErrorJustComplete()
        
        // MARK: Загрузка данных
        Driver<Void>
            .merge(
                input.refreshDataTrigger.asDriver().delay(.milliseconds(1000)),
                .just(())
            )
            .flatMapLatest { [weak self] _ -> Driver<GetAddressListResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.getAddressList()
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .do(
                onNext: { _ in
                    isInitialLoadingFinishedSubject.onNext(true)
                    reloadingFinishedSubject.onNext(())
                }
            )
            .ignoreNil()
            .withLatestFrom(areSectionsExpanded.asDriver(onErrorJustReturn: [:])) { ($0, $1) }
            .do(
                onNext: { [weak self] args in
                    let (newData, expansionStateDict) = args
                    
                    self?.updateSectionExpansionStates(expansionStateDict: expansionStateDict, newData: newData)
                }
            )
            .drive(
                onNext: { [weak self] args in
                    let (newData, _) = args
                    // TODO: нужно добавить загрузку адресов, которые ожидают подтверждения,
                    // затем этот список по аналогии проверить на пустоту
                    guard !newData.isEmpty else {
                        self?.router.trigger(.inputContract)
                        return
                    }
                    
                    self?.loadedData.onNext(newData)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: При скрытии / раскрытии секций передаем информацию о секции, чтобы View могла выполнить скроллинг
        
        let updateKindSubject = PublishSubject<AddressesListSectionUpdateKind>()
        let updateKind = updateKindSubject.asDriverOnErrorJustComplete()
        
        input.guestAccessRequested
            .flatMapLatest { [weak self] identity -> Driver<AddressesListDataItemIdentity?> in
                guard let self = self, case let .object(_, domophoneId, doorId, _) = identity else {
                    return .empty()
                }
                
                return self.apiWrapper.openDoor(domophoneId: domophoneId, doorId: doorId)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .map { _ -> AddressesListDataItemIdentity? in identity }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .withLatestFrom(areObjectsGrantAccessed.asDriverOnErrorJustComplete()) { ($0, $1) }
            .map { args -> (AddressesListDataItemIdentity, [AddressesListDataItemIdentity: Bool]) in
                var (identity, dict) = args
                
                let newState = !dict[identity, default: false]
                dict[identity] = newState
                
                return (identity, dict)
            }
            .drive(
                onNext: { [weak self] args in
                    let (identity, newDict) = args
                    self?.areObjectsGrantAccessed.onNext(newDict)
                    self?.closeObjectAccessAfterTimeout(identity: identity)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: При нажатии на Header, обновляем состояние раскрытости для этой секции
        // Это приведет к обновлению секций
        
        input.itemSelected
            .flatMap { identity -> Driver<String> in
                guard case let .header(addressId) = identity else {
                    return .empty()
                }
                
                return .just(addressId)
            }
            .withLatestFrom(areSectionsExpanded.asDriverOnErrorJustComplete()) { ($0, $1) }
            .map { args -> ((String, Bool), [String: Bool]) in
                var (addressId, dict) = args
                
                let newState = !dict[addressId, default: false]
                dict[addressId] = newState
                
                return ((addressId, newState), dict)
            }
            
            // MARK: Вынес в блок do, чтобы не делать сайд-эффектов в map
            
            .do(
                onNext: { args in
                    let (updatedSectionInfo, _) = args
                    let (addressId, newState) = updatedSectionInfo
                    
                    let identity = AddressesListDataItemIdentity.header(addressId: addressId)
                    
                    updateKindSubject.onNext(
                        newState ?
                            .expand(sectionWithIdentity: identity) :
                            .collapse(sectionWithIdentity: identity)
                    )
                }
            )
            .map { args in
                let (_, dict) = args
                return dict
            }
            .drive(
                onNext: { [weak self] newDict in
                    self?.areSectionsExpanded.onNext(newDict)
                }
            )
            .disposed(by: disposeBag)
        
        let sectionModels = Driver
            .combineLatest(
                loadedData.asDriver(onErrorJustReturn: nil),
                areSectionsExpanded.asDriverOnErrorJustComplete(),
                areObjectsGrantAccessed.asDriverOnErrorJustComplete()
            )
            .map { [weak self] args -> [AddressesListSectionModel] in
                let (loadedData, expansionStateDict, objectAccessDict) = args
                
                guard let self = self, let data = loadedData else {
                    return []
                }
                
                return self.createSections(
                    data: data,
                    expansionStateDict: expansionStateDict,
                    objectAccessDict: objectAccessDict
                )
            }
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            sectionModels: sectionModels,
            updateKind: updateKind,
            isLoading: activityTracker.asDriver(),
            reloadingFinished: reloadingFinished,
            isInitialLoadingFinished: isInitialLoadingFinished
        )
    }

    private func closeObjectAccessAfterTimeout(identity: AddressesListDataItemIdentity) {
        Timer.scheduledTimer(
            withTimeInterval: 5,
            repeats: false
        ) { [weak self] _ in
            guard let self = self, let data = try? self.areObjectsGrantAccessed.value() else {
                return
            }
            
            var newDict = data
            newDict[identity] = false
            
            self.areObjectsGrantAccessed.onNext(newDict)
        }
    }
    
    private func updateSectionExpansionStates(expansionStateDict: [String: Bool], newData: GetAddressListResponseData) {
        var mutableDict = expansionStateDict
        
        newData.enumerated().forEach { args in
            let (offset, address) = args
            
            let addressId = (address.houseId ?? "") + address.address
            mutableDict[addressId] = mutableDict[addressId] ?? (offset == 0 ? true : false)
        }
        
        areSectionsExpanded.onNext(mutableDict)
    }
    
    private func createSections(
        data: GetAddressListResponseData,
        expansionStateDict: [String: Bool],
        objectAccessDict: [AddressesListDataItemIdentity: Bool]
    ) -> [AddressesListSectionModel] {
        // swiftlint:disable:next closure_body_length
        let sectionModels = data.map { address -> AddressesListSectionModel in
            let addressId = (address.houseId ?? "") + address.address
            let isSectionExpanded = expansionStateDict[addressId, default: false]
            
            let header: AddressesListDataItem = .header(
                identity: .header(addressId: addressId),
                address: address.address,
                isExpanded: isSectionExpanded
            )
            
            let objects: [AddressesListDataItem] = {
                guard isSectionExpanded else {
                    return []
                }
                
                let doors = address.doors.map { door -> AddressesListDataItem in
                    let identity = AddressesListDataItemIdentity.object(
                        addressId: addressId,
                        domophoneId: door.domophoneId,
                        doorId: door.doorId,
                        entrance: door.entrance
                    )
                    
                    return AddressesListDataItem.object(
                        identity: identity,
                        type: door.type,
                        name: door.name,
                        isOpened: objectAccessDict[identity, default: false]
                    )
                }
                
                let cameras: AddressesListDataItem? = {
                    guard !address.cctv.isEmpty else {
                        return nil
                    }
                    
                    return .cameras(identity: .cameras(addressId: addressId), numberOfCameras: address.cctv.count)
                }()
                
                return doors + [cameras].compactMap { $0 }
            }()
            
            let section = AddressesListSectionModel(
                identity: addressId,
                items: [header] + objects
            )
            
            return section
        }
        
        return sectionModels
    }
    
}

extension AddressesListViewModel {
    
    struct Input {
        let itemSelected: Driver<AddressesListDataItemIdentity>
        let guestAccessRequested: Driver<AddressesListDataItemIdentity>
        let refreshDataTrigger: Driver<Void>
    }
    
    struct Output {
        let sectionModels: Driver<[AddressesListSectionModel]>
        let updateKind: Driver<AddressesListSectionUpdateKind>
        let isLoading: Driver<Bool>
        let reloadingFinished: Driver<Void>
        let isInitialLoadingFinished: Driver<Bool>
    }
    
}
