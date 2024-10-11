//
//  HomePayViewModel.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 30.05.2024.
//  Copyright © 2024 Layka. All rights reserved.
//
// swiftlint:disable function_body_length cyclomatic_complexity type_body_length

import RxSwift
import RxCocoa
import XCoordinator
import SmartYardSharedDataFramework

class HomePayViewModel: BaseViewModel {
    
    static var shouldForceTransitionForCurrentSession = true

    private let apiWrapper: APIWrapper
    private let pushNotificationService: PushNotificationService
    private let permissionService: PermissionService
    private let accessService: AccessService
    private let alertService: AlertService
    private let logoutHelper: LogoutHelper
    
    private let router: WeakRouter<HomePayRoute>
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
    private let contracts = PublishSubject<[ContractFaceObject]>()
    private let parentStatusUpdate = PublishSubject<(Int, Bool)>()
    private let detailsUpdate = PublishSubject<(ContractFaceObject, [DetailObject])>()

    init(
        apiWrapper: APIWrapper,
        permissionService: PermissionService,
        pushNotificationService: PushNotificationService,
        accessService: AccessService,
        alertService: AlertService,
        logoutHelper: LogoutHelper,
        router: WeakRouter<HomePayRoute>
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
                NotificationCenter.default.rx.notification(.paymentCompleted).asDriverOnErrorJustComplete().mapToTrue(),
                hasNetworkBecomeReachable.mapToFalse(),
                .just(false)
            )
            .flatMapLatest { [weak self] forceRefresh -> Driver<(GetContractsResponseData?, GetOptionsResponseData?)?> in
                guard let self = self else {
                    return .empty()
                }
                
                return Single
                    .zip(
                        self.apiWrapper.getContracts(forceRefresh: forceRefresh),
                        self.apiWrapper.getOptions().catchAndReturn(nil)
                    )
                    .trackActivity(interactionBlockingRequestTracker)
                    .trackError(self.errorTracker)
                    .map { args -> (GetContractsResponseData?, GetOptionsResponseData?)? in
                        let (contractsResponse, optionsResponse) = args
                        
                        guard let uContracts = contractsResponse else {
                            return nil
                        }
                        
                        return (uContracts, optionsResponse)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
        
        // MARK: Запрос на обновление, который вызван рефреш контролом
        
        let reloadingFinishedSubject = PublishSubject<Void>()
        let reloadingFinished = reloadingFinishedSubject.asDriverOnErrorJustComplete()
        
        let nonBlockingRefresh = input.refreshDataTrigger
            .asDriver()
            .delay(.milliseconds(1000))
            .flatMapLatest { [weak self] _ -> Driver<(GetContractsResponseData?, GetOptionsResponseData?)?> in
                guard let self = self else {
                    return .empty()
                }

                return Single
                    .zip(
                        self.apiWrapper.getContracts(forceRefresh: true),
                        self.apiWrapper.getOptions().catchAndReturn(nil)
                    )
                    .trackError(self.errorTracker)
                    .map { args -> (GetContractsResponseData?, GetOptionsResponseData?)? in
                        let (contractsResponse, optionsResponse) = args
                        
                        guard let uContracts = contractsResponse else {
                            return nil
                        }
                        
                        return (uContracts, optionsResponse)
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
            .map { args -> (GetContractsResponseData?) in
                let (contracts, options) = args
                
                // отсылаем уведомление о полученных опциях внешнего вида приложения
                if let options = options {
                    NotificationCenter.default.post(
                        name: .updateOptions,
                        object: nil,
                        userInfo: options.dictionary
                    )
                }

                return contracts
            }
            .flatMapLatest{ [weak self] contractsData -> Driver<[ContractFaceObject]> in
                
                var contracts: [ContractFaceObject] = []
                
                if let contractsData = contractsData {
                    let toDate = Date()
                    let fromDate = Calendar.novokuznetskCalendar.date(byAdding: .day, value: -30, to: toDate)!
                    contracts = contractsData.enumerated().map { offset, element in
                            let camera = ContractFaceObject(
                                number: offset + 1,
                                houseId: element.houseId,
                                contractName: element.contractName,
                                address: element.address, 
                                cityName: element.city,
                                balance: element.balance,
                                services: element.servicesAvailability,
                                clientId: String(element.clientId),
                                limitStatus: element.limitStatus,
                                limitAvailable: element.limitAvailable && !element.limitStatus,
                                limitDays: element.limitDays,
                                parentEnable: element.isParentControl,
                                parentStatus: element.parentControlStatus,
                                details: ContractDetailObject(
                                    fromDay: fromDate,
                                    toDay: toDate,
                                    details: []
                                )
                            )
                        return camera
                    }
                }
            
                return .just(contracts)
            }
            .drive(
                onNext: { [weak self] contracts in
                    guard !contracts.isEmpty
                        || !HomePayViewModel.shouldForceTransitionForCurrentSession else {
                        HomePayViewModel.shouldForceTransitionForCurrentSession = false
                        self?.router.trigger(.inputContract(isManualTrigger: false))
                        return
                    }

                    self?.contracts.onNext(contracts)
                }
            )
            .disposed(by: disposeBag)
        
        input.notificationTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.notifications)
                }
            )
            .disposed(by: disposeBag)
        
        input.parentInfoTrigger
            .drive(
                onNext: { [weak self] contract in
                    guard let self = self, contract.parentEnable == true else {
                        return
                    }
                    if contract.parentStatus == nil {
                        self.parentStatusUpdate.onNext((contract.number, false))
                    }
                    self.router.trigger(.showModal(withContent: .aboutParentControl))
                }
            )
            .disposed(by: disposeBag)
        
        input.parentStatusTrigger
            .flatMapLatest { [weak self] contract -> Driver<ContractFaceObject?> in
                guard let self = self, contract.parentEnable == true else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .setParentControl(clientId: contract.clientId)
                    .trackError(self.errorTracker)
                    .map {
                        guard $0 != nil else {
                            return nil
                        }
                        return contract
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] contract in
                    guard let self = self else {
                        return
                    }
                    
                    if let status = contract.parentStatus {
                        self.parentStatusUpdate.onNext((contract.number, !status))
                    } else {
                        self.parentStatusUpdate.onNext((contract.number, true))
                        self.router.trigger(.showModal(withContent: .aboutParentControl))
                    }

                }
            )
            .disposed(by: disposeBag)

        input.settingsTrigger
            .drive(
                onNext: { [weak self] contract in
                    guard let self = self else {
                        return
                    }
                    self.router.trigger(.accessService(address: contract.address, flatId: contract.clientId, clientId: contract.clientId))
                }
            )
            .disposed(by: disposeBag)
        
        input.limitTrigger
            .drive(
                onNext: { [weak self] contract in
                    self?.router.trigger(.activateLimit(contract: contract))
                }
            )
            .disposed(by: disposeBag)
        
        input.detailsTrigger
            .flatMapLatest { [weak self] contract -> Driver<([DetailObject], ContractFaceObject)?> in
                guard let self = self else {
                    return .just(nil)
                }
                
                let formatter = DateFormatter()

                formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
                formatter.dateFormat = "dd.MM.yyyy"

                return self.apiWrapper
                    .payBalanceDetail(
                        id: contract.clientId,
                        to: formatter.string(from: contract.details.toDay),
                        from: formatter.string(from: contract.details.fromDay)
                    )
                    .trackError(self.errorTracker)
                    .map {
                        guard let response = $0 else {
                            return ([], contract)
                        }
                        let details = response.map { element in
                           return DetailObject(
                            type: element.type,
                            title: element.title,
                            date: element.date,
                            summa: element.summa
                           )
                        }
                        return (details, contract)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] args in
                    let (details, contract) = args
                    
                    guard let self = self else {
                        return
                    }
                    self.detailsUpdate.onNext((contract, details))
                }
            )
            .disposed(by: disposeBag)
        
        input.calendarDetailsTrigger
            .flatMapLatest { [weak self] range -> Driver<([DetailObject], ContractFaceObject)?> in
                
                guard let self = self, let range = range, let fromDay = range.fromDay, let toDay = range.toDay else {
                    return .just(nil)
                }
                
                var contract = range.contract
                
                let formatter = DateFormatter()
                formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
                formatter.dateFormat = "dd.MM.yyyy"

                return self.apiWrapper
                    .payBalanceDetail(
                        id: contract.clientId,
                        to: formatter.string(from: toDay),
                        from: formatter.string(from: fromDay)
                    )
                    .trackError(self.errorTracker)
                    .map {
                        guard let response = $0 else {
                            return ([], contract)
                        }
                        contract.details.fromDay = fromDay
                        contract.details.toDay = toDay
                        let details = response.map { element in
                           return DetailObject(
                            type: element.type,
                            title: element.title,
                            date: element.date,
                            summa: element.summa
                           )
                        }
                        return (details, contract)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] args in
                    let (details, contract) = args
                    
                    guard let self = self else {
                        return
                    }
                    self.detailsUpdate.onNext((contract, details))
                }
            )
            .disposed(by: disposeBag)

        input.sendDetailsTrigger
            .ignoreNil()
            .drive(
                onNext: { [weak self] range in
                    self?.router.trigger(.sendDetails(range: range))
                }
            )
            .disposed(by: disposeBag)
        
        input.paymentTrigger
            .drive(
                onNext: { [weak self] contract in
                    self?.router.trigger(.paymentPopup(clientId: contract.clientId, contract: contract.contractName))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            reloadingFinished: reloadingFinished,
            contracts: contracts.asDriver(onErrorJustReturn: []),
            parentStatus: parentStatusUpdate.asDriverOnErrorJustComplete(),
            details: detailsUpdate.asDriverOnErrorJustComplete(),
            shouldBlockInteraction: interactionBlockingRequestTracker.asDriver()
        )
    }
}

extension HomePayViewModel {
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

extension HomePayViewModel {
    
    struct Input {
        let refreshDataTrigger: Driver<Void>
        let notificationTrigger: Driver<Void>
        let limitTrigger: Driver<ContractFaceObject>
        let settingsTrigger: Driver<ContractFaceObject>
        let detailsTrigger: Driver<ContractFaceObject>
        let paymentTrigger: Driver<ContractFaceObject>
        let parentInfoTrigger: Driver<ContractFaceObject>
        let parentStatusTrigger: Driver<ContractFaceObject>
        let calendarDetailsTrigger: Driver<DetailRange?>
        let sendDetailsTrigger: Driver<DetailRange?>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let reloadingFinished: Driver<Void>
        let contracts: Driver<[ContractFaceObject]>
        let parentStatus: Driver<(Int, Bool)>
        let details: Driver<(ContractFaceObject, [DetailObject])>
        let shouldBlockInteraction: Driver<Bool>
    }
    
}
// swiftlint:enable function_body_length cyclomatic_complexity type_body_length
