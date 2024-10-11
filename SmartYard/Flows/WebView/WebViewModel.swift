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

class WebViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<WebViewRoute>
    private let url: URL?
    private let content: String?
    private let baseURL: String?
    
    init(
        apiWrapper: APIWrapper,
        router: WeakRouter<WebViewRoute>,
        url: URL? = nil,
        content: String? = nil,
        baseURL: String? = nil
    ) {
        self.apiWrapper = apiWrapper
        self.router = router
        self.url = url
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
    
    func transform(_ input: Input) -> Output {
        let activityTracker = ActivityTracker()
        
        input.openUrlTrigger
            .drive(
                onNext: { [weak self] url, backButtonLabel, transition in
                    switch transition {
                    case .popup:
                        self?.router.trigger(
                            .webViewPopup(
                                url: url,
                                backButtonLabel: backButtonLabel
                            )
                        )
                    
                    case .replace:
                        self?.router.trigger(
                            .webView(
                                url: url,
                                backButtonLabel: backButtonLabel,
                                push: false
                            ),
                            with: TransitionOptions(animated: false)
                        )
                    case .push:
                        self?.router.trigger(
                            .webView(
                                url: url,
                                backButtonLabel: backButtonLabel,
                                push: true
                            )
                        )
                    }
                }
            )
            .disposed(by: disposeBag)
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        let urlToLoadSubject = PublishSubject<URL>()
        
        /// content, baseURL
        let contentToLoadSubject = PublishSubject<(String, String)>()
        
        let hasNetworkBecomeReachable = apiWrapper.isReachableObservable
            .asDriver(onErrorJustReturn: false)
            .distinctUntilChanged()
            .skip(1)
            .isTrue()
            .withLatestFrom(input.isViewVisible)
            .isTrue()
            .mapToVoid()
            
        
        Driver
            .merge(input.viewWillAppearTrigger.distinctUntilChanged().mapToVoid(), hasNetworkBecomeReachable)
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    if let url = self.url {
                        urlToLoadSubject.onNext(url)
                    } else {
                        guard let content = self.content, let baseURL = self.baseURL else {
                            return
                        }
                        
                        contentToLoadSubject.onNext((content, baseURL))
                    }
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            loadURL: urlToLoadSubject.asDriverOnErrorJustComplete(),
            loadContent: contentToLoadSubject.asDriverOnErrorJustComplete(),
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension WebViewModel {
    
    struct Input {
        let viewWillAppearTrigger: Driver<Bool>
        let isViewVisible: Driver<Bool>
        let shareUrlTrigger: Driver<URL>
        let backTrigger: Driver<Void>
        let openUrlTrigger: Driver<(URL, String, TransitionType)>
    }
    
    struct Output {
        let loadURL: Driver<URL>
        let loadContent: Driver<(String, String)>
        let isLoading: Driver<Bool>
    }
    
}
// swiftlint:enable function_body_length
