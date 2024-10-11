//
//  MyYardViewModel.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 05.04.2024.
//  Copyright © 2024 Layka. All rights reserved.
//
// swiftlint:disable function_body_length large_tuple type_body_length closure_body_length cyclomatic_complexity

import RxSwift
import RxCocoa
import XCoordinator
import SmartYardSharedDataFramework

class MyYardViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let pushNotificationService: PushNotificationService
    private let permissionService: PermissionService
    private let accessService: AccessService
    private let alertService: AlertService
    private let logoutHelper: LogoutHelper
    
    private let router: WeakRouter<MyYardRoute>
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
    private let cameras = PublishSubject<[CameraExtendedObject]>()
    private let intercoms = PublishSubject<[IntercomCamerasObject]>()
    private let codeUpdate = PublishSubject<(Int, String)>()

    private let areIntercomGrantAccessed = BehaviorSubject<[IntercomCamerasObject: Bool]>(value: [:])

    init(
        apiWrapper: APIWrapper,
        permissionService: PermissionService,
        pushNotificationService: PushNotificationService,
        accessService: AccessService,
        alertService: AlertService,
        logoutHelper: LogoutHelper,
        router: WeakRouter<MyYardRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.permissionService = permissionService
        self.pushNotificationService = pushNotificationService
        self.accessService = accessService
        self.alertService = alertService
        self.logoutHelper = logoutHelper
        
        self.router = router
    }
    
    private let appVersionCheckResult = BehaviorSubject<APIAppVersionCheckResult?>(value: nil)

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
        // приложение иногда запрашивает токен, когда он ещё неизвестен
        // и показывает пользователю ошибку "Отсутствует FCM-токен"
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
                NotificationCenter.default.rx.notification(.updateCameraOrder).asDriverOnErrorJustComplete().mapToTrue(),
                hasNetworkBecomeReachable.mapToFalse(),
                .just(false)
            )
            .flatMapLatest { [weak self] forceRefresh -> Driver<(AllCamerasResponseData?, OverviewCCTVResponseData, AllPlacesResponseData?, GetOptionsResponseData?)?> in
                guard let self = self else {
                    return .empty()
                }
                
                return Single
                    .zip(
                        self.apiWrapper.getAllCameras(forceRefresh: forceRefresh),
                        self.apiWrapper.getOverviewCCTV(forceRefresh: forceRefresh),
                        self.apiWrapper.getAllPlaces(forceRefresh: forceRefresh),
                        self.apiWrapper.getOptions().catchAndReturn(nil)
                    )
                    .trackActivity(interactionBlockingRequestTracker)
                    .trackError(self.errorTracker)
                    .map { args -> (AllCamerasResponseData?, OverviewCCTVResponseData, AllPlacesResponseData?, GetOptionsResponseData?)? in
                        let (allCamerasResponse, overviewCCTVResponse, placesListResponse, optionsResponse) = args
                        
                        guard let uOverviewCCTV = overviewCCTVResponse else {
                            return nil
                        }
                        
                        return (allCamerasResponse, uOverviewCCTV, placesListResponse, optionsResponse)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
        
        // MARK: Запрос на обновление, который вызван рефреш контролом
        let reloadingFinishedSubject = PublishSubject<Void>()
        let reloadingFinished = reloadingFinishedSubject.asDriverOnErrorJustComplete()
        
        let nonBlockingRefresh = input.refreshDataTrigger
            .asDriver()
            .delay(.milliseconds(1000))
            .flatMapLatest { [weak self] _ -> Driver<(AllCamerasResponseData?, OverviewCCTVResponseData, AllPlacesResponseData?, GetOptionsResponseData?)?> in
                guard let self = self else {
                    return .empty()
                }

                return Single
                    .zip(
                        self.apiWrapper.getAllCameras(forceRefresh: true),
                        self.apiWrapper.getOverviewCCTV(forceRefresh: true),
                        self.apiWrapper.getAllPlaces(forceRefresh: true),
                        self.apiWrapper.getOptions().catchAndReturn(nil)
                    )
                    .trackError(self.errorTracker)
                    .map { args -> (AllCamerasResponseData?, OverviewCCTVResponseData, AllPlacesResponseData?, GetOptionsResponseData?)? in
                        let (allCamerasResponse, overviewCCTVResponse, placesListResponse, optionsResponse) = args
                        
                        guard let uOverviewCCTV = overviewCCTVResponse else {
                            return nil
                        }
                        
                        return (allCamerasResponse, uOverviewCCTV, placesListResponse, optionsResponse)
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
            .map { args -> (AllCamerasResponseData?, OverviewCCTVResponseData, AllPlacesResponseData?) in
                var (camerasUser, camerasCity, places, options) = args
                
                // отсылаем уведомление о полученных опциях внешнего вида приложения
                if let options = options {
                    NotificationCenter.default.post(
                        name: .updateOptions,
                        object: nil,
                        userInfo: options.dictionary
                    )
                }

                return (camerasUser, camerasCity, places)
            }
            .flatMapLatest{ [weak self] args -> Driver<([CameraExtendedObject], [IntercomCamerasObject])> in
                let (camerasUser, camerasCity, places) = args
                
                // MARK: Здесь мы должны заполнить список камер исходя из следующих условий
                // 1. Камер должно быть нечетное количество не меньше 9
                // 2. Первыми заполняются камеры пользователя
                // 3. При заполнении исключаем домофонные камеры (по наличию дверей)
                // 4. Если после заполнения пользовательских камер количество меньше 9
                //    или четное количество, заполняем оставшиеся места городскими камерами

                var cameras: [CameraExtendedObject] = []
                var intercoms: [IntercomCamerasObject] = []
                
                if let camerasUser = camerasUser {
                    cameras = camerasUser.enumerated().map { offset, element in
                            let camera = CameraExtendedObject(
                                id: element.id,
                                position: element.coordinate,
                                cameraNumber: offset + 1,
                                name: element.name,
                                video: element.video,
                                token: element.token,
                                doors: [],
                                flatIds: [],
                                type: .home,
                                status: nil
                            )
                        return camera
                    }
                }
            
                if !camerasCity.isEmpty {
                    if cameras.count < 9 {
                        let citycameras = camerasCity[..<(9 - cameras.count)]
                        let count = cameras.count
                        cameras += citycameras.enumerated().map { offset, element in
                            let camera = CameraExtendedObject(
                                id: element.id,
                                position: element.coordinate,
                                cameraNumber: offset + 1 + count,
                                name: element.name,
                                video: element.video,
                                token: element.token,
                                doors: [],
                                flatIds: [],
                                type: .city,
                                status: nil
                            )
                            return camera
                        }
                    } else if cameras.count % 2 == 0 {
                        let camera = camerasCity[0]
                        cameras.append(CameraExtendedObject(
                            id: camera.id,
                            position: camera.coordinate,
                            cameraNumber: cameras.count,
                            name: camera.name,
                            video: camera.video,
                            token: camera.token,
                            doors: [],
                            flatIds: [],
                            type: .city,
                            status: nil
                        ))
                    }
                }
                
                guard let places = places else {
                    return .just((cameras, []))
                }
                
                // MARK: Заполняем объекты домофонов
                intercoms = places.enumerated().map { offset, element in
                    let place = IntercomCamerasObject(
                        number: offset, 
                        name: element.name,
                        domophoneId: element.domophoneId,
                        doorId: element.doorId,
                        type: element.type,
                        hasPlog: element.hasPlog,
                        address: element.address,
                        houseId: element.houseId,
                        flatId: element.flatId,
                        flat: element.flat,
                        clientId: element.clientId,
                        events: element.events,
                        blocked: nil,
                        cameras: element.cctv.enumerated().map { camoffset, camelement in
                            let camera = CameraInversObject(
                                number: camoffset,
                                camId: camelement.id,
                                name: camelement.name,
                                video: camelement.video,
                                token: camelement.token,
                                houseId: camelement.houseId
                            )
                            return camera
                        },
                        doorcode: element.doorcode
                    )
                    return place
                }
                
                guard let accessToken = self?.accessService.accessToken,
                      let backendURL = self?.accessService.backendURL else {
                    return .just((cameras, intercoms))
                }
                
                let sharedObjects = places.map { place in
                    return SmartYardSharedObject(
                        objectName: place.name,
                        objectAddress: place.address ?? "",
                        domophoneId: place.domophoneId,
                        doorId: place.doorId,
                        blockReason: nil,
                        logoImageName: place.type.iconImageName
                    )
                }
            
                let sharedData = SmartYardSharedData(
                    accessToken: accessToken,
                    backendURL: backendURL,
                    sharedObjects: sharedObjects
                )
                
                SmartYardSharedDataUtilities.saveSharedData(data: sharedData)

                return .just((cameras, intercoms))
            }
            .drive(
                onNext: { [weak self] args in
                    let (cameras, intercoms) = args
                    self?.cameras.onNext(cameras)
                    self?.intercoms.onNext(intercoms)
                }
            )
            .disposed(by: disposeBag)
        
        input.selectCameraTrigger
            .drive(
                onNext: { [weak self] camera in
                    guard let self = self else {
                        return
                    }
                    switch camera.type {
                    case .home, .intercom:
                        self.router.trigger(.homeCamera(houseId: "", camId: camera.id))
                    case .city:
                        let cityCamera = CityCameraObject(
                            id: camera.id,
                            position: camera.position,
                            cameraNumber: camera.cameraNumber,
                            name: camera.name,
                            video: camera.video,
                            token: camera.token
                        )
                        self.router.trigger(.cityCamera(camera: cityCamera))
                        break
                    default:
                        break
                    }
                }
            )
            .disposed(by: disposeBag)
        
        input.camerasHintTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.homeCamera(houseId: "", camId: nil))
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
        
        input.doorCodeRefreshTrigger
            .flatMapLatest { [weak self] intercom -> Driver<(ResetCodeResponseData?, IntercomCamerasObject)?> in
                guard let self = self, let flatId = intercom.flatId else {
                    return .empty()
                }
                
                return self.apiWrapper.resetCode(flatId: String(flatId), domophoneId: intercom.domophoneId)
                    .trackError(self.errorTracker)
                    .trackActivity(self.activityTracker)
                    .map {
                        guard let response = $0 else {
                            return nil
                        }
                        
                        return (response, intercom)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] args in
                    let (codeResponse, intercom) = args
                    guard let self = self, let codeResponse = codeResponse, let code = codeResponse.code else {
                        return
                    }
                    
                    self.codeUpdate.onNext((intercom.number, code))
                }
            )
            .disposed(by: disposeBag)

        input.eventsTrigger
            .drive(
                onNext: { [weak self] intercom in
                    guard let self = self, intercom.hasPlog else {
                        self?.router.trigger(.alert(title: "Список событий", message: "События за доступный период отсутствуют."))
                        return
                    }
                    self.router.trigger(.historyEvents(houseId: intercom.houseId, address: intercom.address ?? ""))
                }
            )
            .disposed(by: disposeBag)
        
        input.faceidTrigger
            .drive(
                onNext: { [weak self] intercom in
                    guard let self = self, let flatId = intercom.flatId else {
                        return
                    }
                    let clientId: String? = {
                        guard let clientId = intercom.clientId else {
                            return nil
                        }
                        return String(clientId)
                    }()
                    self.router.trigger(.accessService(address: intercom.address ?? "", flatId: String(flatId), clientId: clientId))
                }
            )
            .disposed(by: disposeBag)

        input.fullscreenTrigger
            .drive(
                onNext: { [weak self] intercom in
                    self?.router.trigger(.fullscreen(houseId: "", camId: intercom.camId))
                }
            )
            .disposed(by: disposeBag)
        
        input.openDoorTrigger
            .flatMapLatest { [weak self] intercom -> Driver<IntercomCamerasObject?> in
                
                guard let self = self, 
                      let address = intercom.address,
                      let type = intercom.type else {
                    return .empty()
                }
                
                // Донейтим системе сведения об открывании дверей.
                let object = SmartYardSharedObject(
                    objectName: intercom.name,
                    objectAddress: address,
                    domophoneId: intercom.domophoneId,
                    doorId: intercom.doorId,
                    blockReason: nil,
                    logoImageName: type.iconImageName
                )
                
                SmartYardSharedFunctions.donateInteraction(object)
                
                return self.apiWrapper
                    .openDoor(domophoneId: intercom.domophoneId, doorId: intercom.doorId, blockReason: intercom.blocked)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .map { _ -> IntercomCamerasObject? in intercom }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .withLatestFrom(areIntercomGrantAccessed.asDriverOnErrorJustComplete()) { ($0, $1) }
            .map { args -> (IntercomCamerasObject, [IntercomCamerasObject: Bool]) in
                var (intercom, dict) = args
                
                let newState = !dict[intercom, default: false]
                dict[intercom] = newState
                
                return (intercom, dict)
            }
            .drive(
                onNext: { [weak self] args in
                    let (intercom, newDict) = args
                    self?.areIntercomGrantAccessed.onNext(newDict)
                    self?.closeIntercomAccessAfterTimeout(camera: intercom)
                }
            )
            .disposed(by: disposeBag)
        
        input.shareOpendoorTrigget
            .flatMapLatest { [weak self] intercom -> Driver<ShareGenerateResponseData?> in
                guard let self = self, let houseId = intercom.houseId, let flat = intercom.flat else {
                    return .empty()
                }
                return self.apiWrapper
                    .shareGenerate(
                        houseId: houseId,
                        flat: flat,
                        domophoneId: intercom.domophoneId
                    )
                    .trackError(self.errorTracker)
                    .trackActivity(self.activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] response in
                    self?.router.trigger(.share(items: [response.title, response.text, response.url]))
                }
            )
            .disposed(by: disposeBag)
        
        input.callPhoneTrigger
            .drive( 
                onNext: { [weak self] callnumber in
                    guard let url = URL(string: callnumber),
                          UIApplication.shared.canOpenURL(url) else {
                        print(callnumber)
                        self?.router.trigger(.share(items: [callnumber]))
                        return
                    }
                    print("URL", url)
                    UIApplication.shared.open(url)
                }
            )
            .disposed(by: disposeBag)
        
        input.chatSelectTrigger
            .flatMapLatest { [weak self] chat -> Driver<(ChatwootGetChatListResponseData?, String)?> in
                guard let self = self else {
                    return .empty()
                }
                return self.apiWrapper.chatwootlist()
                    .trackError(errorTracker)
                    .map {
                        guard let response = $0 else {
                            return nil
                        }
                        
                        return (response, chat)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] args in
                    let (chatlist, chat) = args
                    
                    guard let self = self, let chatlist = chatlist,
                          let chat = (chatlist.first { $0.chat == chat }) else {
                              return
                          }
                    self.router.trigger(.chatContact(chat: chat.chat, name: chat.name))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            reloadingFinished: reloadingFinished,
            cameras: cameras.asDriver(onErrorJustReturn: []),
            intercoms: intercoms.asDriver(onErrorJustReturn: []),
            code: codeUpdate.asDriverOnErrorJustComplete(),
            shouldBlockInteraction: interactionBlockingRequestTracker.asDriver()
        )
    }
}

extension MyYardViewModel {
    private func closeIntercomAccessAfterTimeout(camera: IntercomCamerasObject) {
        Timer.scheduledTimer(
            withTimeInterval: 5,
            repeats: false
        ) { [weak self] _ in
            guard let self = self, let data = try? self.areIntercomGrantAccessed.value() else {
                return
            }
            
            var newDict = data
            newDict[camera] = false
            
            self.areIntercomGrantAccessed.onNext(newDict)
        }
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

extension MyYardViewModel {
    
    struct Input {
        let selectCameraTrigger: Driver<CameraExtendedObject>
        let refreshDataTrigger: Driver<Void>
        let camerasHintTrigger: Driver<Void>
        let addAddressTrigger: Driver<Void>
        let shareOpendoorTrigget: Driver<IntercomCamerasObject>
        let eventsTrigger: Driver<IntercomCamerasObject>
        let faceidTrigger: Driver<IntercomCamerasObject>
        let fullscreenTrigger: Driver<CameraInversObject>
        let doorCodeRefreshTrigger: Driver<IntercomCamerasObject>
        let openDoorTrigger: Driver<IntercomCamerasObject>
        let callPhoneTrigger: Driver<String>
        let chatSelectTrigger: Driver<String>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let reloadingFinished: Driver<Void>
        let cameras: Driver<[CameraExtendedObject]>
        let intercoms: Driver<[IntercomCamerasObject]>
        let code: Driver<(Int, String)>
        let shouldBlockInteraction: Driver<Bool>
    }
    
}
// swiftlint:enable function_body_length large_tuple type_body_length closure_body_length cyclomatic_complexity
