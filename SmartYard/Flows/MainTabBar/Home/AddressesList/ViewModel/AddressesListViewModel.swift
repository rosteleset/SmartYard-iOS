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
    
    // MARK: Словарь необходим для того, чтобы хранить состояния раскрытости секций
    private let areSectionsExpanded = BehaviorSubject<[String: Bool]>(value: [:])
    // MARK: Словарь необходим для того, чтобы хранить состояния открытости объекта
    private let areObjectsGrantAccessed = BehaviorSubject<[String: Bool]>(value: [:])
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        let errorTracker = ErrorTracker()
        
        // MARK: Создаем подписки для всех загруженных адресов
        // Потом это уйдет в другое место скорее всего, да и логика будет другая
        
        apiWrapper.getVerifyedAddresses()
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .map { addresses in addresses.map { $0.clientId } }
            .flatMapLatest { [weak self] clientIds -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                let queries = clientIds.map {
                    self.pushNotificationService.updatePushNotificationsState(forClientId: $0, newState: .on)
                }
                
                return Single<Void?>.zip(queries)
                    .map { _ -> Void? in () }
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: {
                    print("DEBUG: Подписки на все загруженные адреса успешно созданы")
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: При скрытии / раскрытии секций передаем информацию о секции, чтобы View могла выполнить скроллинг
        
        let updateKindSubject = PublishSubject<AddressesListSectionUpdateKind>()
        let updateKind = updateKindSubject.asDriverOnErrorJustComplete()
        
        input.guestAccessRequested
            .flatMap { identity -> Driver<String> in
                guard case let .object(objectId) = identity else {
                    return .empty()
                }
                return .just(objectId)
            }
            .withLatestFrom(areObjectsGrantAccessed.asDriverOnErrorJustComplete()) { ($0, $1) }
            .map { args -> (String, [String: Bool]) in
                var (objectId, dict) = args
                
                let newState = !dict[objectId, default: false]
                dict[objectId] = newState
                
                return (objectId, dict)
            }
            .drive(
                onNext: { [weak self] args in
                    let (objectId, newDict) = args
                    self?.areObjectsGrantAccessed.onNext(newDict)
                    self?.closeObjectAccessAfterTimeout(objectId: objectId)
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
        
        let sectionModels = Observable
            .combineLatest(areSectionsExpanded, areObjectsGrantAccessed)
            .map { [weak self] args -> [AddressesListSectionModel] in
                let (expansionStateDict, objectAccessDict) = args
                
                return self?.createMockSections(
                    expansionStateDict: expansionStateDict,
                    objectAccessDict: objectAccessDict
                    ) ?? []
            }
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            sectionModels: sectionModels.asDriverOnErrorJustComplete(),
            updateKind: updateKind
        )
    }

    private func closeObjectAccessAfterTimeout(objectId: String) {
        Timer.scheduledTimer(
            withTimeInterval: 5,
            repeats: false
        ) { [weak self] _ in
            guard let self = self,
                  let data = try? self.areObjectsGrantAccessed.value()
            else {
                return
            }
            
            var newDict = data
            newDict[objectId] = false
            
            self.areObjectsGrantAccessed.onNext(newDict)
        }
    }
    
    // swiftlint:disable:next function_body_length
    private func createMockSections(
        expansionStateDict: [String: Bool],
        objectAccessDict: [String: Bool]
    ) -> [AddressesListSectionModel] {
        // MARK: Пока моки, но в принципе, нет ничего сложного прикрутить сюда реальные данные
        // Просто будем пробегать в цикле по всем адресам и генерировать для них секции
        
        let firstAddressId = "1000"
        let isFirstSectionExpanded = expansionStateDict[firstAddressId, default: false]
        
        let firstSectionHeader: AddressesListDataItem = .header(
            identity: .header(addressId: firstAddressId),
            address: "г. Тамбов, ул. Советская, 16, кв. 4",
            isExpanded: isFirstSectionExpanded
        )
        
        // swiftlint:disable:next closure_body_length
        let firstSectionObjects: [AddressesListDataItem] = {
            guard isFirstSectionExpanded else {
                return []
            }
            
            let firstSectionFirstObjectId = "FirstSectionFirstObject"
            let firstSectionFirstObject: AddressesListDataItem = .object(
                identity: .object(id: firstSectionFirstObjectId),
                type: .barrier,
                name: "Шлагбаум Север",
                isOpened: objectAccessDict[firstSectionFirstObjectId, default: false]
            )
            
            let firstSectionSecondObjectId = "FirstSectionSecondObject"
            let firstSectionSecondObject: AddressesListDataItem = .object(
                identity: .object(id: firstSectionSecondObjectId),
                type: .gate,
                name: "Ворота Юг",
                isOpened: objectAccessDict[firstSectionSecondObjectId, default: false]
            )
            
            let firstSectionThirdObjectId = "FirstSectionThirdObject"
            let firstSectionThirdObject: AddressesListDataItem = .object(
                identity: .object(id: "FirstSectionThirdObject"),
                type: .house,
                name: "Подъезд 1",
                isOpened: objectAccessDict[firstSectionThirdObjectId, default: false]
            )
            
            let firstSectionCameraObject: AddressesListDataItem = .cameras(
                identity: .cameras(addressId: firstAddressId),
                numberOfCameras: 3
            )
            
            return [
                firstSectionFirstObject,
                firstSectionSecondObject,
                firstSectionThirdObject,
                firstSectionCameraObject
            ]
        }()

        let firstSection = AddressesListSectionModel(
            identity: firstAddressId,
            items: [firstSectionHeader] + firstSectionObjects
        )
        
        let secondAddressId = "2000"
        let isSecondSectionExpanded = expansionStateDict[secondAddressId, default: false]
        
        let secondSectionHeader: AddressesListDataItem = .header(
            identity: .header(addressId: secondAddressId),
            address: "г. Тамбов, ул. Мичуринская, 141А",
            isExpanded: isSecondSectionExpanded
        )
        
        let secondSectionObjects: [AddressesListDataItem] = {
            guard isSecondSectionExpanded else {
                return []
            }
            
            let secondSectionFirstObjectId = "SecondSectionFirstObject"
            let secondSectionFirstObject: AddressesListDataItem = .object(
                identity: .object(id: secondSectionFirstObjectId),
                type: .house,
                name: "Подъезд 1",
                isOpened: objectAccessDict[secondSectionFirstObjectId, default: false]
            )
            
            return [secondSectionFirstObject]
        }()
        
        let secondSection = AddressesListSectionModel(
            identity: secondAddressId,
            items: [secondSectionHeader] + secondSectionObjects
        )
        
        let thirdAddressId = "3000"
        let isThirdSectionExpanded = expansionStateDict[thirdAddressId, default: false]
        
        let thirdSectionHeader: AddressesListDataItem = .header(
            identity: .header(addressId: thirdAddressId),
            address: "г. Котовск, ул. Зимняя, 20",
            isExpanded: isThirdSectionExpanded
        )
        
        let thirdSectionObjects: [AddressesListDataItem] = {
            guard isThirdSectionExpanded else {
                return []
            }
            
            let thirdSectionFirstObjectId = "ThirdSectionFirstObject"
            let thirdSectionFirstObject: AddressesListDataItem = .object(
                identity: .object(id: "ThirdSectionFirstObject"),
                type: .house,
                name: "Подъезд 1",
                isOpened: objectAccessDict[thirdSectionFirstObjectId, default: false]
            )
            
            return [thirdSectionFirstObject]
        }()
        
        let thirdSection = AddressesListSectionModel(
            identity: "3000",
            items: [thirdSectionHeader] + thirdSectionObjects
        )
        
        return [firstSection, secondSection, thirdSection]
    }
    
}

extension AddressesListViewModel {
    
    struct Input {
        let itemSelected: Driver<AddressesListDataItemIdentity>
        let guestAccessRequested: Driver<AddressesListDataItemIdentity>
    }
    
    struct Output {
        let sectionModels: Driver<[AddressesListSectionModel]>
        let updateKind: Driver<AddressesListSectionUpdateKind>
    }
    
}
