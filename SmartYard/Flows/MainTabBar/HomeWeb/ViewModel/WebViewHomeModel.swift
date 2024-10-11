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

class WebViewHomeModel: BaseViewModel {
    
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

    public let router: WeakRouter<HomeWebRoute>
    private var url: URL?
    private let content: String?
    private let baseURL: String?
    private var urlNotLoaded: Bool = true
    private var hasOptionsLoaded = BehaviorSubject(value: false)
    
    init(
        apiWrapper: APIWrapper,
        permissionService: PermissionService,
        pushNotificationService: PushNotificationService,
        accessService: AccessService,
        alertService: AlertService,
        logoutHelper: LogoutHelper,
        router: WeakRouter<HomeWebRoute>,
        content: String? = nil,
        baseURL: String? = nil
    ) {
        self.apiWrapper = apiWrapper
        self.permissionService = permissionService
        self.pushNotificationService = pushNotificationService
        self.accessService = accessService
        self.alertService = alertService
        self.logoutHelper = logoutHelper
        
        self.router = router
        self.content = content
        self.baseURL = baseURL
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
                    self?.getOptions()
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
        
        input.notificationTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.notifications)
                }
            )
            .disposed(by: disposeBag)
        
        let urlToLoadSubject = PublishSubject<URL>()
        
        Driver
            .merge(
                input.viewWillAppearTrigger.distinctUntilChanged().mapToVoid(),
                hasNetworkBecomeReachable,
                hasOptionsLoaded.asDriverOnErrorJustComplete().mapToVoid()
            )
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    if let url = self.url,
                       self.urlNotLoaded {
                        urlToLoadSubject.onNext(url)
                        self.urlNotLoaded = false
                    }
                    self.pushNotificationService.synchronizeBadgeCount()
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            loadURL: urlToLoadSubject.asDriverOnErrorJustComplete(),
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension WebViewHomeModel {
    func getOptions(){
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
                          let url = URL(string: result.centraScreenUrl) else {
                        return
                    }
                    
//                    self.accessService.centraScreenUrl = result.centraScreenUrl ?? ""
//                    self.accessService.intercomScreenUrl = result.intercomScreenUrl ?? ""
//                    self.accessService.activeTab = result.activeTab ?? "centra"
                    if self.accessService.centraScreenUrl != self.url?.absoluteString {
                        self.urlNotLoaded = true
                    }
                    self.url = url
                    self.hasOptionsLoaded.onNext(true)
                }
            )
            .disposed(by: disposeBag)
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

extension WebViewHomeModel {
    
    struct Input {
        let viewWillAppearTrigger: Driver<Bool>
        let isViewVisible: Driver<Bool>
        let shareUrlTrigger: Driver<URL>
        let notificationTrigger: Driver<Void>
        let openUrlTrigger: Driver<(URL, String, TransitionType)>
    }
    
    struct Output {
        let loadURL: Driver<URL>
//        let loadContent: Driver<(String, String)>
        let isLoading: Driver<Bool>
    }
    
}
// swiftlint:enable function_body_length
