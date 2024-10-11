//
//  NotificationsViewModel.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import RxSwift
import RxCocoa
import XCoordinator
import SmartYardSharedDataFramework

class WebViewIntercomModel: BaseViewModel {
    
    // MARK: Я в курсе, что это хреновая идея
    // Но это самый простой способ хранить значение переменной для одной сессии (до перезапуска)
    static var shouldForceTransitionForCurrentSession = true

    private let apiWrapper: APIWrapper
    private let pushNotificationService: PushNotificationService
    private let permissionService: PermissionService
    private let accessService: AccessService
    private let alertService: AlertService
    private let logoutHelper: LogoutHelper

    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()

    public let router: WeakRouter<IntercomWebRoute>
    private var url: URL?
    private var urlNotLoaded: Bool = true
    
    init(
        apiWrapper: APIWrapper,
        permissionService: PermissionService,
        pushNotificationService: PushNotificationService,
        accessService: AccessService,
        alertService: AlertService,
        logoutHelper: LogoutHelper,
        router: WeakRouter<IntercomWebRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.permissionService = permissionService
        self.pushNotificationService = pushNotificationService
        self.accessService = accessService
        self.alertService = alertService
        self.logoutHelper = logoutHelper
        
        self.router = router
        
    }
    
    func getUrl() -> URL? {
        guard let url = self.url else {
            return nil
        }
        return url
    }
    
    func getUrlString() -> String {
        guard let url = self.url?.absoluteString else {
            return ""
        }
        return url
    }
    
    private let appVersionCheckResult = BehaviorSubject<APIAppVersionCheckResult?>(value: nil)

    func transform(_ input: Input) -> Output {
        let hasNetworkBecomeReachable = apiWrapper.isReachableObservable
            .asDriver(onErrorJustReturn: false)
            .distinctUntilChanged()
            .skip(1)
            .isTrue()
            .mapToVoid()
        
        let errorTracker = ErrorTracker()
        let activityTracker = ActivityTracker()
        
        errorTracker.asDriver()
            .catchAuthorizationError { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.logoutHelper.showAuthErrorAlert(
                    activityTracker: activityTracker,
                    errorTracker: errorTracker,
                    disposeBag: self.disposeBag
                )
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Запрос на обновление, который должен скрывать все происходящее за скелетоном

        self.getOptions()
        self.getListAddress()

        input.openUrlTrigger
            .drive(
                onNext: { [weak self] url, backButtonLabel, transition in
                    switch transition {
                    case .popup:
                        print("popup")
//                        self?.router.trigger(
//                            .webViewPopup(
//                                url: url,
//                                backButtonLabel: backButtonLabel
//                            )
//                        )
                    case .replace:
                        self?.router.trigger(
                            .main,
                            with: TransitionOptions(animated: false)
                        )
                    case .push:
                        print("push")
//                        self?.router.trigger(
//                            .webView(
//                                url: url,
//                                backButtonLabel: backButtonLabel,
//                                push: true
//                            )
//                        )
                    }
                }
            )
            .disposed(by: disposeBag)
        
        let urlToLoadSubject = PublishSubject<URL>()
        
        Driver
            .merge(
                input.viewWillAppearTrigger.distinctUntilChanged().mapToVoid(),
                hasNetworkBecomeReachable
            )
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    if let url = URL(string: self.accessService.intercomScreenUrl),
                       self.urlNotLoaded {
                        urlToLoadSubject.onNext(url)
                        self.urlNotLoaded = false
                    }
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            loadURL: urlToLoadSubject.asDriverOnErrorJustComplete(),
//            loadContent: contentToLoadSubject.asDriverOnErrorJustComplete(),
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension WebViewIntercomModel {
    func getOptions() {
        apiWrapper.getOptions()
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] result in
                    NotificationCenter.default.post(
                        name: .updateOptions,
                        object: nil,
                        userInfo: result.dictionary
                    )
                    
                    guard let self = self,
                          let url = URL(string: result.intercomScreenUrl) else {
                        return
                    }
                    
                    if self.accessService.intercomScreenUrl != self.url?.absoluteString {
                        self.urlNotLoaded = true
                    }
                    self.url = url
                }
            )
            .disposed(by: disposeBag)
    }
    func getListAddress(){
        apiWrapper.getAddressList(forceRefresh: true)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] result in
                    var listAddresses = result
                    
                    var movingElements: GetAddressListResponseData = []
                    for item in listAddresses where item.doors.isEmpty == false {
                            movingElements.append(item)
                    }
                    listAddresses = movingElements + listAddresses.filtered({ $0.doors.isEmpty }, map: { $0 })

                    guard !listAddresses.isEmpty  else {
                        return
                    }
                    
                    guard let accessToken = self?.accessService.accessToken,
                          let backendURL = self?.accessService.backendURL else {
                        return
                    }
                    
                    let sharedObjects = listAddresses.flatMap { addressObject -> [SmartYardSharedObject] in
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
    }
}

extension WebViewIntercomModel {
    
    struct Input {
        let viewWillAppearTrigger: Driver<Bool>
        let isViewVisible: Driver<Bool>
        let shareUrlTrigger: Driver<URL>
        let openUrlTrigger: Driver<(URL, String, TransitionType)>
    }
    
    struct Output {
        let loadURL: Driver<URL>
        let isLoading: Driver<Bool>
    }
    
}
// swiftlint:enable function_body_length
