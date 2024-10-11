//
//  AcceptOffertaByContractViewModel.swift
//  SmartYard
//
//  Created by devcentra on 19.02.2024.
//  Copyright © 2024 Layka. All rights reserved.
//
// swiftlint:disable function_body_length

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class AcceptOffertaByContractViewModel: BaseViewModel {
    
//    private let router: WeakRouter<HomeRoute>?
    private let router: WeakRouter<MyYardRoute>?
    private let routerhomepay: WeakRouter<HomePayRoute>?
    private let routerweb: WeakRouter<HomeWebRoute>?
//    private let routerintercom: WeakRouter<IntercomWebRoute>?

    private let issueService: IssueService
    private let apiWrapper: APIWrapper
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    
    private var login: String?
    private var password: String?
    private var houseId: String?
    private var flat: String?

    private var offersModels = BehaviorSubject<[OffertaCellModel]>(value: [])
    private var isAbleToProceed = BehaviorSubject<Bool>(value: false)

    init(
        routerweb: WeakRouter<HomeWebRoute>,
        issueService: IssueService,
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        offers: [APIOffers]
    ) {
        self.routerweb = routerweb
        self.router = nil
        self.routerhomepay = nil
        self.issueService = issueService
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        
        let offersModels = offers.enumerated().map { offset, element in
            guard let encodedString = element.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: encodedString) else {
                return OffertaCellModel(
                    id: String(offset),
                    name: element.name,
                    url: nil,
                    state: false
                )
            }
            return OffertaCellModel(
                id: String(offset),
                name: element.name,
                url: url,
                state: false
            )
        }
        
        self.offersModels = BehaviorSubject<[OffertaCellModel]>(value: offersModels)
    }
    
    init(
        routerhomepay: WeakRouter<HomePayRoute>,
        issueService: IssueService,
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        offers: [APIOffers]
    ) {
        self.routerhomepay = routerhomepay
        self.routerweb = nil
        self.router = nil
        self.issueService = issueService
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        
        let offersModels = offers.enumerated().map { offset, element in
            guard let encodedString = element.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: encodedString) else {
                return OffertaCellModel(
                    id: String(offset),
                    name: element.name,
                    url: nil,
                    state: false
                )
            }
            return OffertaCellModel(
                id: String(offset),
                name: element.name,
                url: url,
                state: false
            )
        }
        
        self.offersModels = BehaviorSubject<[OffertaCellModel]>(value: offersModels)
    }
    
    init(
        router: WeakRouter<MyYardRoute>,
        issueService: IssueService,
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        offers: [APIOffers]
    ) {
        self.router = router
        self.routerweb = nil
        self.routerhomepay = nil
        self.issueService = issueService
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        
        let offersModels = offers.enumerated().map { offset, element in
            guard let encodedString = element.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: encodedString) else {
                return OffertaCellModel(
                    id: String(offset),
                    name: element.name,
                    url: nil,
                    state: false
                )
            }
            return OffertaCellModel(
                id: String(offset),
                name: element.name,
                url: url,
                state: false
            )
        }
        
        self.offersModels = BehaviorSubject<[OffertaCellModel]>(value: offersModels)
    }
    
    func updateLP(login: String, password: String) {
        self.login = login
        self.password = password
    }
    
    func updateHF(houseId: String, flat: String?) {
        self.houseId = houseId
        if let flat = flat {
            self.flat = flat
        }
    }
    
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
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
                    self?.router?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    self?.routerweb?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    self?.routerhomepay?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
     
        input.signInTapped
            .withLatestFrom(isAbleToProceed.asDriver(onErrorJustReturn: false))
            .isTrue()
            .flatMapLatest { [weak self] _ -> Driver<Void?>in
                
                guard let self = self else {
                    return .just(nil)
                }
                
                if let login = self.login, let password = self.password {
                    return self.apiWrapper
                        .acceptOfferta(
                            login: login,
                            password: password
                        )
                        .trackActivity(activityTracker)
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
                }
                if let houseId = self.houseId {
                    return self.apiWrapper
                        .acceptOfferta(
                            houseId: houseId,
                            flat: self.flat
                        )
                        .trackActivity(activityTracker)
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
                }
                return .just(nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
                    self?.router?.trigger(.main)
                    self?.routerweb?.trigger(.main)
                    self?.routerhomepay?.trigger(.main)
                    NotificationCenter.default.post(name: .addressAdded, object: nil)
                }
            )
            .disposed(by: disposeBag)
        
        input.itemStateChanged
            .withLatestFrom(self.offersModels.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    var (itemIndex, offersModels) = args

                    guard let self = self, let index = itemIndex else {
                        return
                    }
                    
                    offersModels.enumerated().forEach { offset, _ in
                        if offset == index {
                            offersModels[offset].toggleState()
                        }
                    }
                    
                    if let notAppliedOffer = offersModels.first { $0.state == false } {
                        self.isAbleToProceed.onNext(false)
                    } else {
                        self.isAbleToProceed.onNext(true)
                    }
                    
                    self.offersModels.onNext(offersModels)
                }
            )
            .disposed(by: disposeBag)

        input.itemShare
            .withLatestFrom(self.offersModels.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    var (itemIndex, offersModels) = args
                    
                    guard let self = self, let index = itemIndex else {
                        return
                    }
                    
                    guard let url = try? offersModels[index].url else {
                        return
                    }
  
                    self.router?.trigger(.pdfView(url: url))
                    self.routerweb?.trigger(.pdfView(url: url))
                    self.routerhomepay?.trigger(.pdfView(url: url))
                }
            )
            .disposed(by: disposeBag)
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router?.trigger(.back)
                    self?.routerweb?.trigger(.back)
                    self?.routerhomepay?.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            offersModels: offersModels.asDriver(onErrorJustReturn: []),
            isLoading: activityTracker.asDriver(),
            isAbleToProceed: isAbleToProceed.asDriver(onErrorJustReturn: false)
        )
    }
    
}

extension AcceptOffertaByContractViewModel {
    
    struct Input {
        let signInTapped: Driver<Void>
        let itemStateChanged: Driver<Int?>
        let itemShare: Driver<Int?>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let offersModels: Driver<[OffertaCellModel]>
        let isLoading: Driver<Bool>
        let isAbleToProceed: Driver<Bool>
    }
    
}
// swiftlint:enable function_body_length
