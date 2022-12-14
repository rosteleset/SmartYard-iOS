//
//  AddressesViewModel.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator
import SmartYardSharedDataFramework

// swiftlint:disable:next type_body_length
class AddressesListViewModel: BaseViewModel {
    
    // MARK: Я в курсе, что это хреновая идея
    // Но это самый простой способ хранить значение переменной для одной сессии (до перезапуска)
    static var shouldForceTransitionForCurrentSession = true
    
    private let apiWrapper: APIWrapper
    private let pushNotificationService: PushNotificationService
    private let permissionService: PermissionService
    private let accessService: AccessService
    private let alertService: AlertService
    private let logoutHelper: LogoutHelper
    
    private let router: WeakRouter<HomeRoute>
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
    init(
        apiWrapper: APIWrapper,
        permissionService: PermissionService,
        pushNotificationService: PushNotificationService,
        accessService: AccessService,
        alertService: AlertService,
        logoutHelper: LogoutHelper,
        router: WeakRouter<HomeRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.permissionService = permissionService
        self.pushNotificationService = pushNotificationService
        self.accessService = accessService
        self.alertService = alertService
        self.logoutHelper = logoutHelper
        
        self.router = router
    }
    
    private let loadedApprovedAddressesData = BehaviorSubject<GetAddressListResponseData?>(value: nil)
    private let loadedUnapprovedAddressesData = BehaviorSubject<GetListConnectResponseData?>(value: nil)
    
    // MARK: Словарь необходим для того, чтобы хранить состояния раскрытости секций
    private let areSectionsExpanded = BehaviorSubject<[String: Bool]>(value: [:])
    // MARK: Словарь необходим для того, чтобы хранить состояния предоставленного доступа к объекту
    private let areObjectsGrantAccessed = BehaviorSubject<[AddressesListDataItemIdentity: Bool]>(value: [:])
    
    private let appVersionCheckResult = BehaviorSubject<APIAppVersionCheckResult?>(value: nil)
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func transform(_ input: Input) -> Output {
        let hasNetworkBecomeReachable = apiWrapper.isReachableObservable
            .asDriver(onErrorJustReturn: false)
            .distinctUntilChanged()
            .skip(1)
            .isTrue()
            .mapToVoid()
        
        errorTracker.asDriver()
            .catchAuthorizationError { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.logoutHelper.showAuthErrorAlert(
                    activityTracker: self.activityTracker,
                    errorTracker: self.errorTracker,
                    disposeBag: self.disposeBag
                )
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] error in
                    if (error as NSError) == NSError.PermissionError.noCameraPermission {
                        let msg = "Чтобы использовать эту функцию, перейдите в настройки и предоставьте доступ к камере"
                        
                        self?.router.trigger(.appSettings(title: "Нет доступа к камере", message: msg))
                        
                        return
                    }
                    
                    self?.alertService.showAlert(
                        title: "Ошибка",
                        message: error.localizedDescription,
                        priority: 250
                    )
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Заказчик попросил запрашивать все разрешения сразу после авторизации. Хозяин - барин
        
        permissionService.requestAccessToMic()
            .asDriver(onErrorJustReturn: nil)
            .drive()
            .disposed(by: disposeBag)
        
        permissionService.hasAccess(to: .video)
            .asDriver(onErrorJustReturn: nil)
            .drive()
            .disposed(by: disposeBag)
        
        // MARK: Подписка на уведомления
        
        pushNotificationService
            .registerForPushNotifications(
                voipToken: accessService.prefersVoipForCalls ? accessService.voipToken : nil
            )
            // приложение иногда запрашивает токен, когда он ещё неизвестен и показывает пользователю ошибку "Отсутствует FCM-токен"
            // дабы не портить пользователю настроение я решил убрать отображение этой ошибки в интерфейсе.
            // .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: {
                    print("DEBUG: Successfully subscribed to push notifications")
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Проверка версии приложения
        
        apiWrapper.checkAppVersion()
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] result in
                    self?.appVersionCheckResult.onNext(result)
                    self?.handleAppVersionCheckResult(result)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Если нажать на "Обновить", то алерт закроется. При этом юзер может просто сразу же зайти обратно
        // Поэтому при повторном разворачивании приложения снова показываем алерт
        
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(appVersionCheckResult.asDriver(onErrorJustReturn: nil))
            .filter { $0 == .forceUpgrade }
            .ignoreNil()
            .drive(
                onNext: { [weak self] result in
                    self?.handleAppVersionCheckResult(result)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Запрос на обновление, который должен скрывать все происходящее за скелетоном
        
        let interactionBlockingRequestTracker = ActivityTracker()
        
        let blockingRefresh = Driver
            .merge(
                NotificationCenter.default.rx.notification(.addressDeleted).asDriverOnErrorJustComplete().mapToTrue(),
                NotificationCenter.default.rx.notification(.addressAdded).asDriverOnErrorJustComplete().mapToTrue(),
                NotificationCenter.default.rx.notification(.addressNeedUpdate).asDriverOnErrorJustComplete().mapToTrue(),
                hasNetworkBecomeReachable.mapToFalse(),
                .just(false)
            )
            .flatMapLatest { [weak self] forceRefresh -> Driver<(GetAddressListResponseData, GetListConnectResponseData)?> in
                guard let self = self else {
                    return .empty()
                }
                
                return Single
                    .zip(
                        self.apiWrapper.getAddressList(forceRefresh: forceRefresh),
                        self.apiWrapper.getListConnect(forceRefresh: forceRefresh)
                    )
                    .trackActivity(interactionBlockingRequestTracker)
                    .trackError(self.errorTracker)
                    .map { args -> (GetAddressListResponseData, GetListConnectResponseData)? in
                        let (firstResponse, secondResponse) = args
                        
                        guard let uFirstResponse = firstResponse, let uSecondResponse = secondResponse else {
                            return nil
                        }
                        
                        return (uFirstResponse, uSecondResponse)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
        
        // MARK: Запрос на обновление, который вызван рефреш контролом
        
        let reloadingFinishedSubject = PublishSubject<Void>()
        let reloadingFinished = reloadingFinishedSubject.asDriverOnErrorJustComplete()
        
        let nonBlockingRefresh = input.refreshDataTrigger
            .asDriver()
            .delay(.milliseconds(1000))
            .flatMapLatest { [weak self] _ -> Driver<(GetAddressListResponseData, GetListConnectResponseData)?> in
                guard let self = self else {
                    return .empty()
                }

                return Single
                    .zip(self.apiWrapper.getAddressList(forceRefresh: true), self.apiWrapper.getListConnect(forceRefresh: true))
                    .trackError(self.errorTracker)
                    .map { args -> (GetAddressListResponseData, GetListConnectResponseData)? in
                        let (firstResponse, secondResponse) = args
                        
                        guard let uFirstResponse = firstResponse, let uSecondResponse = secondResponse else {
                            return nil
                        }
                        
                        return (uFirstResponse, uSecondResponse)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .do(
                onNext: { _ in
                    reloadingFinishedSubject.onNext(())
                }
            )
        
        Driver
            .merge(blockingRefresh, nonBlockingRefresh)
            .ignoreNil()
            .map { args -> (GetAddressListResponseData, GetListConnectResponseData) in
                var (approvedAddresses, uSecondResponse) = args
                
                // перемещаем наверх позиции в которых есть домофон
                var movingElements: GetAddressListResponseData = []
                for item in approvedAddresses where item.doors.isEmpty == false {
                        movingElements.append(item)
                }
                approvedAddresses = movingElements + approvedAddresses.filtered({ $0.doors.isEmpty }, map: { $0 })
                
                return (approvedAddresses, uSecondResponse)
            }
            .withLatestFrom(areSectionsExpanded.asDriver(onErrorJustReturn: [:])) { ($0, $1) }
            .do(
                onNext: { [weak self] args in
                    let (newData, expansionStateDict) = args
                    let (approvedAddresses, _) = newData
                    
                    self?.updateSectionExpansionStates(
                        expansionStateDict: expansionStateDict,
                        newData: approvedAddresses
                    )
                }
            )
            .drive(
                onNext: { [weak self] args in
                    let (newData, _) = args
                    let (approvedAddresses, unapprovedAddresses) = newData
                    
                    // MARK: Если хотя бы одно из условий выполняется:
                    // 1. Список подтвержденных адресов НЕ пустой
                    // 2. Список неподтвержденных адресов НЕ пустой
                    // 3. Если мы уже зафорсили транзишен один раз и больше не можем это сделать
                    // То - просто отображаем список адресов на главном экране
                    
                    // Если не выполняется ни одно из них - форсим переход на экран "Добавление адреса"
                    
                    guard !approvedAddresses.isEmpty
                        || !unapprovedAddresses.isEmpty
                        || !AddressesListViewModel.shouldForceTransitionForCurrentSession else {
                        AddressesListViewModel.shouldForceTransitionForCurrentSession = false
                        self?.router.trigger(.inputContract(isManualTrigger: false))
                        return
                    }
                    
                    self?.loadedApprovedAddressesData.onNext(approvedAddresses)
                    self?.loadedUnapprovedAddressesData.onNext(unapprovedAddresses)
                    
                    guard let accessToken = self?.accessService.accessToken,
                          let backendURL = self?.accessService.backendURL else {
                        return
                    }
                    
                    let sharedObjects = approvedAddresses.flatMap { addressObject -> [SmartYardSharedObject] in
                        let address = addressObject.address
                        
                        return addressObject.doors.map {
                            SmartYardSharedObject(
                                objectName: $0.name,
                                objectAddress: address,
                                domophoneId: $0.domophoneId,
                                doorId: $0.doorId,
                                blockReason: $0.blocked,
                                logoImageName: $0.type.iconImageName
                            )
                        }
                    }
                    
                    let sharedData = SmartYardSharedData(
                        accessToken: accessToken,
                        backendURL: backendURL,
                        sharedObjects: sharedObjects
                    )
                    
                    SmartYardSharedDataUtilities.saveSharedData(data: sharedData)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на кнопку "Открыть"
        
        input.guestAccessRequested
            .withLatestFrom(loadedApprovedAddressesData.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<AddressesListDataItemIdentity?> in
                let (identity, loadedData) = args
                
                guard let self = self,
                    let unwrappedData = loadedData,
                    case let .object(addressId, domophoneId, doorId, _) = identity,
                    let matchingAddress = (
                        unwrappedData.first { address in
                            address.houseId == addressId
                        }
                    ),
                    let matchingDoor = (
                        matchingAddress.doors.first { door in
                            door.domophoneId == domophoneId && door.doorId == doorId
                        }
                    ) else {
                    return .empty()
                }
                
                // Донейтим системе сведения об откывании дверей.
                let object = SmartYardSharedObject(
                    objectName: matchingDoor.name,
                    objectAddress: matchingAddress.address,
                    domophoneId: domophoneId,
                    doorId: doorId,
                    blockReason: matchingDoor.blocked,
                    logoImageName: matchingDoor.type.iconImageName
                )
                
                SmartYardSharedFunctions.donateInteraction(object)
                
                return self.apiWrapper
                    .openDoor(domophoneId: domophoneId, doorId: doorId, blockReason: matchingDoor.blocked)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
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
        
        // MARK: При скрытии / раскрытии секций передаем информацию о секции, чтобы View могла выполнить скроллинг
        
        let updateKindSubject = PublishSubject<AddressesListSectionUpdateKind>()
        let updateKind = updateKindSubject.asDriverOnErrorJustComplete()
        
        // Обработка нажатия по заявке (адрес в красной рамке)
        input.itemSelected
            .withLatestFrom(loadedUnapprovedAddressesData.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMap { args -> Driver<APIIssueConnect> in
                let (identity, unapprovedAddresses) = args
                
                guard case let .unapprovedObject(issueId, _) = identity else {
                    return .empty()
                }
                
                let issue = unapprovedAddresses?.first { $0.key == issueId }
                
                guard let uIssue = issue else {
                    return .empty()
                }
                
                return .just(uIssue)
            }
            .drive(
                onNext: { [weak self] issue in
                    guard let self = self else {
                        return
                    }
                    
                    self.router.trigger(.serviceSoonAvailable(issue: issue))
                }
            )
            .disposed(by: disposeBag)
        
        // Нажатие на кнопку "Видеонаблюдение"
        input.itemSelected
            .flatMap { identity -> Driver<String> in
                guard case let .cameras(addressId) = identity else {
                    return .empty()
                }
                
                return .just(addressId)
            }
            .withLatestFrom(loadedApprovedAddressesData.asDriverOnErrorJustComplete()) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (addressId, loadedAddresses) = args
                    let matchingAddress = loadedAddresses?.first { $0.houseId == addressId }
                    
                    guard let uHouseId = matchingAddress?.houseId, let uAddress = matchingAddress?.address else {
                        return
                    }
                
                    self?.router.trigger(.yardCamerasMap(houseId: uHouseId, address: uAddress))
                }
            )
            .disposed(by: disposeBag)
        
        // Нажатие на кнопку "истории"
        input.itemSelected
            .flatMap { identity -> Driver<String> in
                guard case let .history(addressId) = identity else {
                    return .empty()
                }
                
                return .just(addressId)
            }
            .withLatestFrom(loadedApprovedAddressesData.asDriverOnErrorJustComplete()) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (addressId, loadedAddresses) = args
                    let matchingAddress = loadedAddresses?.first { $0.houseId == addressId }
                    
                    guard let uHouseId = matchingAddress?.houseId, let uAddress = matchingAddress?.address else {
                        return
                    }
                    
                    self?.router.trigger(.history(houseId: uHouseId, address: uAddress))
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
        
        input.addAddressTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.inputContract(isManualTrigger: true))
                }
            )
            .disposed(by: disposeBag)
        
        input.issueQrCodeTrigger
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.permissionService.hasAccess(to: .video)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    
                    self.router.trigger(.qrCodeScan(delegate: self))
                }
            )
            .disposed(by: disposeBag)
        
        let sectionModels = Driver
            .combineLatest(
                loadedApprovedAddressesData.asDriver(onErrorJustReturn: nil),
                loadedUnapprovedAddressesData.asDriver(onErrorJustReturn: nil),
                areSectionsExpanded.asDriverOnErrorJustComplete(),
                areObjectsGrantAccessed.asDriverOnErrorJustComplete()
            )
            .map { [weak self] args -> [AddressesListSectionModel] in
                let (loadedApprovedAddressesData, loadedUnapprovedAddressesData,
                    expansionStateDict, objectAccessDict) = args
                
                guard let self = self,
                      let approvedAddresses = loadedApprovedAddressesData,
                      let unapprovedAddresses = loadedUnapprovedAddressesData
                else {
                    return []
                }
                
                return self.createSections(
                    approvedAddressesData: approvedAddresses,
                    unapprovedAddressesData: unapprovedAddresses,
                    expansionStateDict: expansionStateDict,
                    objectAccessDict: objectAccessDict
                )
            }
        
        return Output(
            sectionModels: sectionModels,
            updateKind: updateKind,
            isLoading: activityTracker.asDriver(),
            reloadingFinished: reloadingFinished,
            shouldBlockInteraction: interactionBlockingRequestTracker.asDriver()
        )
    }
    
}

extension AddressesListViewModel {
    
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
            
            let addressId = address.houseId
            mutableDict[addressId] = mutableDict[addressId] ?? (offset == 0 ? true : false)
        }
        
        areSectionsExpanded.onNext(mutableDict)
    }
    
    // swiftlint:disable:next function_body_length
    private func createSections(
        approvedAddressesData: GetAddressListResponseData,
        unapprovedAddressesData: GetListConnectResponseData,
        expansionStateDict: [String: Bool],
        objectAccessDict: [AddressesListDataItemIdentity: Bool]
    ) -> [AddressesListSectionModel] {
        // swiftlint:disable:next closure_body_length
        var sectionModels = approvedAddressesData.map { address -> AddressesListSectionModel in
            let addressId = address.houseId
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
                    guard address.cctv != 0 else {
                        return nil
                    }
                    
                    return .cameras(identity: .cameras(addressId: addressId), numberOfCameras: address.cctv)
                }()
                
                let history: AddressesListDataItem? = {
                    if address.hasPlog == false {
                        return nil
                    }
                    return .history(identity: .history(addressId: addressId), numberOfEvents: 0)
                }()
                
                return doors + [cameras].compactMap { $0 } + [history].compactMap { $0 }
            }()
            
            let section = AddressesListSectionModel(
                identity: addressId,
                items: [header] + objects
            )
            
            return section
        }
        
        let unapprovedAddressItems = unapprovedAddressesData.compactMap { issueInfo -> AddressesListDataItem? in
            guard let address = issueInfo.address else {
                return nil
            }
            
            return .unapprovedAddresses(
                identity: .unapprovedObject(issueId: issueInfo.key, address: address),
                address: address
            )
        }
        
        unapprovedAddressItems.forEach {
            sectionModels.append(AddressesListSectionModel(identity: String($0.identity.hashValue), items: [$0]))
        }
        
        if sectionModels.isEmpty {
            let emptyStateSection = AddressesListSectionModel(identity: "EmptyStateSection", items: [.emptyState])
            sectionModels.append(emptyStateSection)
        }
        
        return sectionModels
    }
    
    private func handleAppVersionCheckResult(_ result: APIAppVersionCheckResult) {
        switch result {
        case .ok:
            break
            
        case .upgrade:
            let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
            
            let updateAction = UIAlertAction(title: "Обновить", style: .default) { _ in
                guard let url = URL(string: Constants.appstoreUrl) else {
                    return
                }
                
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
            alertService.showDialog(
                title: "Доступна новая версия приложения",
                message: nil,
                actions: [cancelAction, updateAction],
                priority: 5000
            )
            
        case .forceUpgrade:
            let updateAction = UIAlertAction(title: "Обновить", style: .default) { _ in
                guard let url = URL(string: Constants.appstoreUrl) else {
                    return
                }
                
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
            alertService.showDialog(
                title: "Версия приложения устарела",
                message: "Чтобы продолжить пользоваться приложением, пожалуйста, обновите его",
                actions: [updateAction],
                priority: 5000
            )
        }
    }
    
}

extension AddressesListViewModel {
    
    struct Input {
        let itemSelected: Driver<AddressesListDataItemIdentity>
        let guestAccessRequested: Driver<AddressesListDataItemIdentity>
        let refreshDataTrigger: Driver<Void>
        let addAddressTrigger: Driver<Void>
        let issueQrCodeTrigger: Driver<Void>
    }
    
    struct Output {
        let sectionModels: Driver<[AddressesListSectionModel]>
        let updateKind: Driver<AddressesListSectionUpdateKind>
        let isLoading: Driver<Bool>
        let reloadingFinished: Driver<Void>
        let shouldBlockInteraction: Driver<Bool>
    }
    
}

extension AddressesListViewModel: QRCodeScanViewModelDelegate {
    
    func qrCodeScanViewModel(_ viewModel: QRCodeScanViewModel, didExtractCode code: String) {
        router.rx
            .trigger(.back)
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .registerQR(qr: code)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
                    self?.router.trigger(.main)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
