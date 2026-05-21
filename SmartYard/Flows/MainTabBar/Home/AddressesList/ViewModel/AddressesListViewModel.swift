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

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
final class AddressesListViewModel: BaseViewModel {
    
    // MARK: Я в курсе, что это хреновая идея
    // Но это самый простой способ хранить значение переменной для одной сессии (до перезапуска)
    static var shouldForceTransitionForCurrentSession = true
    
    private let apiWrapper: APIWrapper
    private let pushNotificationService: PushNotificationService
    private let permissionService: PermissionService
    private let accessService: AccessService
    private let alertService: AlertService
    private let logoutHelper: LogoutHelper
    private let offlineAddressListDataSource: OfflineAddressListDataSource
    private let networkStateProvider: NetworkStateProviding

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
        router: WeakRouter<HomeRoute>,
        offlineAddressListDataSource: OfflineAddressListDataSource,
        networkStateProvider: NetworkStateProviding
    ) {
        self.apiWrapper = apiWrapper
        self.permissionService = permissionService
        self.pushNotificationService = pushNotificationService
        self.accessService = accessService
        self.alertService = alertService
        self.logoutHelper = logoutHelper
        self.router = router
        self.offlineAddressListDataSource = offlineAddressListDataSource
        self.networkStateProvider = networkStateProvider
    }
    
    private let loadedApprovedAddressesData = BehaviorSubject<GetAddressListResponseData?>(value: nil)
    private let loadedUnapprovedAddressesData = BehaviorSubject<GetListConnectResponseData?>(value: nil)
    private let loadedCamMapData = BehaviorSubject<CamMapCCTVResponseData>(value: [])
    
    // MARK: Словарь необходим для того, чтобы хранить состояния раскрытости секций
    private let areSectionsExpanded = BehaviorSubject<[String: Bool]>(value: [:])
    // MARK: Словарь необходим для того, чтобы хранить состояния предоставленного доступа к объекту
    private let areObjectsGrantAccessed = BehaviorSubject<[AddressesListDataItemIdentity: Bool]>(value: [:])
    
    private let appVersionCheckResult = BehaviorSubject<APIAppVersionCheckResult?>(value: nil)
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func transform(_ input: Input) -> Output {
        let hasNetworkBecomeReachable = networkStateProvider.state
            .asDriverOnErrorJustComplete()
            .distinctUntilChanged()
            .filter { $0 == .online }
            .mapToVoid()

        let stories = Driver
            .merge(
                .just(false),
                input.refreshDataTrigger.asDriver().mapToTrue(),
                hasNetworkBecomeReachable.mapToFalse()
            )
            .flatMapLatest { [weak self] forceRefresh -> Driver<[StoryItem]> in
                guard let self = self else {
                    return .just([])
                }

                return self.apiWrapper
                    .getStories(forceRefresh: forceRefresh)
                    .map { response in
                        response?.map { StoryItem(apiStory: $0) } ?? []
                    }
                    .asDriver(onErrorJustReturn: [])
            }
        let storyCellModels = stories.map { stories in
            stories.map { StoryItemCellModel(storyItem: $0) }
        }
        input.storySelected
            .withLatestFrom(stories) { selectedIndex, stories -> StoryItem? in
                stories.indices.contains(selectedIndex) ? stories[selectedIndex] : nil
            }
            .ignoreNil()
            .drive(with: self) { owner, story in
                guard let url = URL(string: story.url) else {
                    return
                }

                switch story.presentMethod {
                case .webPopupController:
                    owner.router.trigger(.storyWebPopup(url: url))
                case .webViewController:
                    owner.router.trigger(.storyWebView(url: url))
                }
            }
            .disposed(by: disposeBag)

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
                        let msg = L10n.Permissions.Camera.message
                        
                        self?.router.trigger(
                            .appSettings(
                            title: L10n.Permissions.Camera.title,
                            message: msg
                            )
                        )
                        
                        return
                    }
                    
                    self?.alertService.showAlert(
                        title: L10n.Common.error,
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
                    Logger.logDebug("Successfully subscribed to push notifications")
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
                NotificationCenter.default.rx.notification(.addressOrderReset).asDriverOnErrorJustComplete().mapToTrue(),
                hasNetworkBecomeReachable.mapToTrue(),
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
                    .zip(
                        self.apiWrapper.getAddressList(forceRefresh: true),
                        self.apiWrapper.getListConnect(forceRefresh: true)
                    )
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
            .merge(
                NotificationCenter.default.rx.notification(.addressDeleted).asDriverOnErrorJustComplete().mapToVoid(),
                NotificationCenter.default.rx.notification(.addressAdded).asDriverOnErrorJustComplete().mapToVoid(),
                NotificationCenter.default.rx.notification(.addressNeedUpdate).asDriverOnErrorJustComplete().mapToVoid(),
                NotificationCenter.default.rx.notification(.addressOrderReset).asDriverOnErrorJustComplete().mapToVoid(),
                hasNetworkBecomeReachable,
                input.refreshDataTrigger.asDriver(),
                .just(())
            )
            .flatMapLatest { [weak self] _ -> Driver<CamMapCCTVResponseData> in
                guard let self = self else {
                    return .empty()
                }

                return self.apiWrapper
                    .getCamMap()
                    .asDriver(onErrorJustReturn: nil)
                    .map { $0 ?? [] }
            }
            .drive(
                onNext: { [weak self] camMap in
                    self?.loadedCamMapData.onNext(camMap)
                }
            )
            .disposed(by: disposeBag)
        
        Driver
            .merge(blockingRefresh, nonBlockingRefresh)
            .ignoreNil()
            .map { args -> (GetAddressListResponseData, GetListConnectResponseData) in
                var (approvedAddresses, uSecondResponse) = args
                
                approvedAddresses = self.applySavedOrder(to: approvedAddresses)
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
                    
                    // TODO: Удалить этот workaround, когда сервер перестанет возвращать дубликаты адресов
                    // В редких случаях сервер дважды присылает один и тот же address с одинаковым houseId — это баг на бэке
                    // Временно фильтруем такие дубликаты вручную
                    var seen = Set<String>()
                    let uniqueApprovedAddresses = approvedAddresses.filter { address in
                        if seen.contains(address.houseId) {
                            return false
                        } else {
                            seen.insert(address.houseId)
                            return true
                        }
                    }

                    self?.cacheOfflineAccess(uniqueApprovedAddresses)
                    self?.logAddressListOpened(addressesCount: uniqueApprovedAddresses.count)

                    let sortedAddresses = self?.applySavedOrder(to: uniqueApprovedAddresses)

                    self?.loadedApprovedAddressesData.onNext(sortedAddresses)
                    self?.loadedUnapprovedAddressesData.onNext(unapprovedAddresses)

                    if let sharedData = self?.buildSharedData(from: uniqueApprovedAddresses) {
                        DispatchQueue.global(qos: .utility).async {
                            SmartYardSharedDataUtilities.saveSharedData(data: sharedData)
                        }
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на кнопку "Открыть"
        
        input.guestAccessRequested
            .flatMapLatest { [weak self] identity -> Driver<AddressesListDataItemIdentity?> in
                guard let self else { return .empty() }
                return self.openDoor(identity: identity).asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] identity in
                    self?.updateObjectAccessState(identity: identity)
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

        input.itemSelected
            .withLatestFrom(
                Driver.combineLatest(
                    loadedApprovedAddressesData.asDriver(onErrorJustReturn: nil),
                    loadedCamMapData.asDriver(onErrorJustReturn: []),
                    areObjectsGrantAccessed.asDriverOnErrorJustComplete()
                )
            ) { ($0, $1.0, $1.1, $1.2) }
            .drive(
                onNext: { [weak self] args in
                    let (identity, loadedAddresses, camMap, objectAccessDict) = args

                    guard
                        let self = self,
                        self.shouldShowEntrancePreviews,
                        let loadedAddresses,
                        let resolvedDoor = self.resolveDoor(identity: identity, in: loadedAddresses),
                        let camera = self.resolveCamera(for: resolvedDoor.door, camMap: camMap)
                    else {
                        return
                    }

                    let accessAction = OnlineFullscreenAccessAction(
                        isOpened: objectAccessDict[identity, default: false],
                        open: { [weak self] completion in
                            guard let self else {
                                completion(false)
                                return
                            }

                            self.openDoorFromFullscreen(identity: identity, completion: completion)
                        }
                    )

                    self.router.trigger(
                        .onlineFullscreen(
                            cameras: [camera],
                            selectedCamera: camera,
                            accessAction: accessAction
                        )
                    )
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
                // swiftlint:disable:next closure_body_length
                onNext: { [weak self] args in
                    let (addressId, loadedAddresses) = args
                    let matchingAddress = loadedAddresses?.first { $0.houseId == addressId }
                    
                    guard let self = self,
                        let uHouseId = matchingAddress?.houseId, let uAddress = matchingAddress?.address else {
                        return
                    }

                    self.logAddressCameraSelected()
                    
                    // проверяем какой тип отображения камер получен от сервера.
                    // возможно три варианта:
                    // старый (.list) - отображение на карте всех камер
                    // новый (.tree) - древовидная структура в которой можно отобразить камеры как на карте,
                    // так и списком с подгруппами.
                    // какой вариант использовать прилетает в приложение от ext/options -> cctvView
                    // выбор пользователя (.userDefined) - если от сервера не пришло ничего, то
                    // даем пользователю выбрать как он хочет отобразить камеры, но по умолчанию будет стоять list 
                    
                    if accessService.showList {
                        self.router.trigger(
                            .yardCamerasMap(
                                houseId: uHouseId,
                                address: uAddress,
                                cameras: nil
                            )
                        )
                    } else {
                        self.apiWrapper.getAllTreeCCTV(houseId: uHouseId)
                            .trackActivity(self.activityTracker)
                            .trackError(self.errorTracker)
                            .asDriver(onErrorJustReturn: nil)
                            // swiftlint:disable:next closure_body_length
                            .drive { response in
                                guard let response = response.optional else {
                                    return
                                }
                                
                                if response.type == .map {
                                    let camObjects: [CameraObject] = {
                                        
                                        guard let cams = response.cameras else {
                                            return []
                                        }
                                        let result = cams.enumerated().map { offset, element in
                                            CameraObject(
                                                id: element.id,
                                                position: element.coordinate,
                                                cameraNumber: offset + 1,
                                                name: element.name,
                                                video: element.video,
                                                token: element.token,
                                                serverType: element.serverType,
                                                hlsMode: element.hlsMode,
                                                hasSound: element.hasSound
                                            )
                                        }
                                        return result
                                        
                                    }()
                                    self.router.trigger(
                                        .yardCamerasMap(
                                            houseId: uHouseId,
                                            address: uAddress,
                                            cameras: camObjects
                                        )
                                    )
                                } else {
                                    self.router.trigger(
                                        .yardCamerasList(
                                            houseId: uHouseId,
                                            address: uAddress,
                                            tree: response,
                                            path: []
                                        )
                                    )
                                }
                            }
                            .disposed(by: self.disposeBag)
                    }
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
                    
                    self?.router.trigger(
                        .history(
                            houseId: uHouseId,
                            address: uAddress
                        )
                    )
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
                onNext: { [weak self] args in
                    let (updatedSectionInfo, _) = args
                    let (addressId, newState) = updatedSectionInfo
                    
                    let identity = AddressesListDataItemIdentity.header(addressId: addressId)

                    self?.logAddressSelected(isExpanded: newState)
                    
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
                loadedCamMapData.asDriver(onErrorJustReturn: []),
                areSectionsExpanded.asDriverOnErrorJustComplete(),
                areObjectsGrantAccessed.asDriverOnErrorJustComplete()
            )
            .map { [weak self] args -> [AddressesListSectionModel] in
                let (
                    loadedApprovedAddressesData,
                    loadedUnapprovedAddressesData,
                    camMapData,
                    expansionStateDict,
                    objectAccessDict
                ) = args
                
                guard let self = self,
                      let approvedAddresses = loadedApprovedAddressesData,
                      let unapprovedAddresses = loadedUnapprovedAddressesData
                else {
                    return []
                }
                
                return self.createSections(
                    approvedAddressesData: approvedAddresses,
                    unapprovedAddressesData: unapprovedAddresses,
                    camMapData: camMapData,
                    expansionStateDict: expansionStateDict,
                    objectAccessDict: objectAccessDict,
                    shouldShowEntrancePreviews: self.shouldShowEntrancePreviews
                )
            }
        
        return Output(
            sectionModels: sectionModels,
            storyCellModels: storyCellModels,
            updateKind: updateKind,
            isLoading: activityTracker.asDriver(),
            reloadingFinished: reloadingFinished,
            shouldBlockInteraction: interactionBlockingRequestTracker.asDriver()
        )
    }
    
}

extension AddressesListViewModel {

    private var approvedAddressesAnalyticsCount: Int? {
        guard let addresses = try? loadedApprovedAddressesData.value() else {
            return nil
        }

        return addresses.count
    }

    private func logAddressListOpened(addressesCount: Int) {
        AppAnalytics.log(
            AppAnalyticsEvent.addressListOpened(
                addressesCount: addressesCount,
                hasMultipleAddresses: addressesCount > 1,
                source: "addresses_refresh"
            )
        )
    }

    private func logAddressCameraSelected() {
        AppAnalytics.log(
            AppAnalyticsEvent.cameraSelected(
                screen: "addresses",
                source: "address_card",
                cameraType: AnalyticsValue.unknown
            )
        )
    }

    private func logAddressSelected(isExpanded: Bool) {
        let addressesCount = approvedAddressesAnalyticsCount
        AppAnalytics.log(
            AppAnalyticsEvent.addressSelected(
                addressesCount: addressesCount,
                hasMultipleAddresses: addressesCount.map { $0 > 1 },
                source: "address_header"
            )
        )
        AppAnalytics.log(
            AppAnalyticsEvent.addressSwitchSuccess(
                addressesCount: addressesCount,
                hasMultipleAddresses: addressesCount.map { $0 > 1 },
                source: isExpanded ? "address_header_expand" : "address_header_collapse"
            )
        )
    }

    private func logDoorOpenTapped(
        screen: String,
        source: String,
        accessType: String
    ) {
        AppAnalytics.log(
            AppAnalyticsEvent.doorOpenTapped(
                screen: screen,
                source: source,
                accessType: accessType
            )
        )
    }

    private func logDoorOpenSuccess(
        screen: String,
        source: String,
        accessType: String
    ) {
        AppAnalytics.log(
            AppAnalyticsEvent.doorOpenSuccess(
                screen: screen,
                source: source,
                accessType: accessType
            )
        )
    }

    private func logDoorOpenFailed(
        screen: String,
        source: String,
        accessType: String,
        errorCode: String?
    ) {
        AppAnalytics.log(
            AppAnalyticsEvent.doorOpenFailed(
                screen: screen,
                source: source,
                accessType: accessType,
                errorCode: errorCode
            )
        )
    }

    private func logQRAccessGrantSuccess(qrType: String) {
        AppAnalytics.log(
            AppAnalyticsEvent.qrAccessGrantSuccess(
                qrType: qrType,
                source: "qr_scanner"
            )
        )
    }

    private func logQRAccessGrantFailed(qrType: String, error: Error) {
        AppAnalytics.log(
            AppAnalyticsEvent.qrAccessGrantFailed(
                qrType: qrType,
                source: "qr_scanner",
                errorCode: AnalyticsError.code(from: error)
            )
        )
    }

    private var shouldShowEntrancePreviews: Bool {
        accessService.entrancesView == APIOptions.EntrancesViewType.preview.rawValue
    }

    private func openDoor(identity: AddressesListDataItemIdentity) -> Observable<AddressesListDataItemIdentity?> {
        openDoor(identity: identity, source: "addresses")
    }

    // swiftlint:disable:next function_body_length
    private func openDoor(
        identity: AddressesListDataItemIdentity,
        source: String
    ) -> Observable<AddressesListDataItemIdentity?> {
        let screen = source == "fullscreen" ? "camera_details" : "addresses"

        guard let loadedData = try? loadedApprovedAddressesData.value(),
              let resolvedDoor = resolveDoor(identity: identity, in: loadedData)
        else {
            logDoorOpenFailed(
                screen: screen,
                source: source,
                accessType: AnalyticsValue.unknown,
                errorCode: "door_not_found"
            )
            return .just(nil)
        }

        let matchingAddress = resolvedDoor.address
        let matchingDoor = resolvedDoor.door
        let accessType = analyticsAccessType(for: matchingDoor.type)

        logDoorOpenTapped(screen: screen, source: source, accessType: accessType)

        let object = SmartYardSharedObject(
            objectName: matchingDoor.name,
            objectAddress: matchingAddress.address,
            domophoneId: matchingDoor.domophoneId,
            doorId: matchingDoor.doorId,
            blockReason: matchingDoor.blocked,
            logoImageName: matchingDoor.type.iconImageName
        )

        SmartYardSharedFunctions.donateInteraction(object)

        return apiWrapper
            .openDoor(
                domophoneId: matchingDoor.domophoneId,
                doorId: matchingDoor.doorId,
                blockReason: matchingDoor.blocked
            )
            .trackActivity(activityTracker)
            .do(
                onNext: { [weak self] _ in
                    self?.logDoorOpenSuccess(
                        screen: screen,
                        source: source,
                        accessType: accessType
                    )
                },
                onError: { [weak self] error in
                    self?.logDoorOpenFailed(
                        screen: screen,
                        source: source,
                        accessType: accessType,
                        errorCode: AnalyticsError.code(from: error)
                    )
                }
            )
            .trackError(errorTracker)
            .map { _ -> AddressesListDataItemIdentity? in identity }
    }

    private func openDoorFromFullscreen(
        identity: AddressesListDataItemIdentity,
        completion: @escaping (Bool) -> Void
    ) {
        openDoor(identity: identity, source: "fullscreen")
            .map { $0 != nil }
            .asDriver(onErrorJustReturn: false)
            .drive(with: self) { owner, didOpen in
                if didOpen {
                    owner.updateObjectAccessState(identity: identity)
                }

                completion(didOpen)
            }
            .disposed(by: disposeBag)
    }

    private func analyticsAccessType(for type: DomophoneObjectType) -> String {
        switch type {
        case .entrance, .wicket:
            return "intercom"
        case .gate:
            return "gate"
        case .barrier:
            return "barrier"
        }
    }

    private func updateObjectAccessState(identity: AddressesListDataItemIdentity) {
        guard let data = try? areObjectsGrantAccessed.value() else {
            return
        }

        var newDict = data
        newDict[identity] = !newDict[identity, default: false]

        areObjectsGrantAccessed.onNext(newDict)
        closeObjectAccessAfterTimeout(identity: identity)
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
            
            let addressId = address.houseId
            mutableDict[addressId] = mutableDict[addressId] ?? (offset == 0 ? true : false)
        }
        
        areSectionsExpanded.onNext(mutableDict)
    }
    
    private func handleAppVersionCheckResult(_ result: APIAppVersionCheckResult) {
        switch result {
        case .ok:
            break
            
        case .upgrade:
            let cancelAction = UIAlertAction(title: L10n.Common.cancel, style: .cancel)
            
            let updateAction = UIAlertAction(title: L10n.App.Update.action, style: .default) { _ in
                guard let url = URL(string: Constants.appstoreUrl) else {
                    return
                }
                
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
            alertService.showDialog(
                title: L10n.App.Update.availableTitle,
                message: nil,
                actions: [cancelAction, updateAction],
                priority: 5000
            )
            
        case .forceUpgrade:
            let updateAction = UIAlertAction(title: L10n.App.Update.action, style: .default) { _ in
                guard let url = URL(string: Constants.appstoreUrl) else {
                    return
                }
                
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
            alertService.showDialog(
                title: L10n.App.Update.requiredTitle,
                message: L10n.App.Update.requiredMessage,
                actions: [updateAction],
                priority: 5000
            )
        }
    }
    
}

extension AddressesListViewModel {
    
    struct Input {
        let itemSelected: Driver<AddressesListDataItemIdentity>
        let storySelected: Driver<Int>
        let guestAccessRequested: Driver<AddressesListDataItemIdentity>
        let refreshDataTrigger: Driver<Void>
        let addAddressTrigger: Driver<Void>
        let issueQrCodeTrigger: Driver<Void>
    }
    
    struct Output {
        let sectionModels: Driver<[AddressesListSectionModel]>
        let storyCellModels: Driver<[StoryItemCellModel]>
        let updateKind: Driver<AddressesListSectionUpdateKind>
        let isLoading: Driver<Bool>
        let reloadingFinished: Driver<Void>
        let shouldBlockInteraction: Driver<Bool>
    }
    
}

extension AddressesListViewModel: QRCodeScanViewModelDelegate {
    
    func qrCodeScanViewModel(_ viewModel: QRCodeScanViewModel, didExtractCode code: String) {
        let qrType = AnalyticsValue.qrType(from: code)

        router.rx
            .trigger(.back)
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .registerQR(qr: code)
                    .do(
                        onSuccess: { [weak self] _ in
                            self?.logQRAccessGrantSuccess(qrType: qrType)
                        },
                        onError: { [weak self] error in
                            self?.logQRAccessGrantFailed(qrType: qrType, error: error)
                        }
                    )
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

extension AddressesListViewModel {
    private func defaultSorted(_ addresses: GetAddressListResponseData) -> GetAddressListResponseData {
        let alphabetic = addresses.sorted {
            $0.address.localizedCaseInsensitiveCompare($1.address) == .orderedAscending
        }
        let withDoors = alphabetic.filter { !$0.doors.isEmpty }
        let withoutDoors = alphabetic.filter { $0.doors.isEmpty }

        return withDoors + withoutDoors
    }
    
    func saveAddressesOrder(_ addresses: GetAddressListResponseData) {
        let order = addresses.map { $0.houseId }
        accessService.userPreferredAddressOrder = order
    }
    
    private func applySavedOrder(to addresses: GetAddressListResponseData) -> GetAddressListResponseData {
        let savedOrder = accessService.userPreferredAddressOrder
        
        guard !savedOrder.isEmpty else {
            return defaultSorted(addresses)
        }
        
        return addresses.sorted { lhs, rhs in
            let lhsIndex = savedOrder.firstIndex(of: lhs.houseId) ?? Int.max
            let rhsIndex = savedOrder.firstIndex(of: rhs.houseId) ?? Int.max
            if lhsIndex != rhsIndex {
                return lhsIndex < rhsIndex
            }
            
            // Если оба отсутствуют в saved, сортируем по алфавиту
            return lhs.address.localizedCaseInsensitiveCompare(rhs.address) == .orderedAscending
        }
    }
    
    func moveApprovedAddress(from fromIndex: Int, to toIndex: Int) {
        var addresses = (try? loadedApprovedAddressesData.value()) ?? []
        guard fromIndex < addresses.count, toIndex <= addresses.count else {
            return
        }
        
        let moved = addresses.remove(at: fromIndex)
        addresses.insert(moved, at: toIndex)
        
        saveAddressesOrder(addresses)
        loadedApprovedAddressesData.onNext(addresses)
    }
    
    func collapseAllSections() {
        let addresses = (try? loadedApprovedAddressesData.value()) ?? []
        let newDict = Dictionary(
            uniqueKeysWithValues: addresses.map { ($0.houseId, false) }
        )
        areSectionsExpanded.onNext(newDict)
    }

}

extension AddressesListViewModel {

    private func buildSharedData(from approved: GetAddressListResponseData) -> SmartYardSharedData? {
        guard let accessToken = accessService.accessToken else { return nil }

        let sharedObjects: [SmartYardSharedObject] = approved.flatMap { approvedItem in
            let address = approvedItem.address
            return approvedItem.doors.map {
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

        return SmartYardSharedData(
            accessToken: accessToken,
            backendURL: accessService.backendURL,
            sharedObjects: sharedObjects
        )
    }

    private func cacheOfflineAccess(_ approved: GetAddressListResponseData) {
        let sanitized = approved.filter { !$0.houseId.isEmpty }
        offlineAddressListDataSource.importAddresses(sanitized)
    }
}
