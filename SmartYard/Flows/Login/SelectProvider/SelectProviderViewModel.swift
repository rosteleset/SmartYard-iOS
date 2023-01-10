//
//  SelectProviderViewModel.swift
//  SmartYard
//
//  Created by LanTa on 13.06.2022.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class SelectProviderViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<AppRoute>
    private let alertService: AlertService
    private let accessService: AccessService
    
    private let selectedProvider = BehaviorSubject<ProviderCellModel?>(value: nil)
    private let providers = BehaviorSubject<[ProviderCellModel]>(value: [])
    private var providersArray: [ProviderCellModel]
    
    init(
        apiWrapper: APIWrapper,
        alertService: AlertService,
        accessService: AccessService,
        router: WeakRouter<AppRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.alertService = alertService
        self.accessService = accessService
        self.router = router
        providersArray = []
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    let nsError = error as NSError
                    
                    switch nsError.code {
                    case 422, 404:
                        let message = "Не удалось загрузить список провайдеров, повторите попытку позднее."
                        self?.router.trigger(.alert(title: "Ошибка", message: message))
                    default:
                        self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    }
                }
            )
            .disposed(by: disposeBag)
        
        self.apiWrapper.getProvidersList()
            .trackActivity(activityTracker)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .drive(
                onNext: { [weak self] apiProviders in
                    guard let self = self, let apiProviders = apiProviders else {
                            self?.providersArray = []
                            return
                        }
                    
                    self.providersArray = apiProviders.map { ProviderCellModel(provider: $0, state: .uncheckedActive) }
                    self.providers.onNext(self.providersArray)
                }
            )
            .disposed(by: disposeBag)
        
        input.inputProviderName
            .drive(
                onNext: { [weak self] filter in
                    guard let self = self else {
                        return
                    }
                    if let filter = filter, !filter.isEmpty {
                        self.providers.onNext(self.providersArray.filter {
                            $0.provider.name.lowercased().contains(filter.lowercased())
                        })
                    } else {
                        self.providers.onNext(self.providersArray)
                    }
                }
            )
            .disposed(by: disposeBag)
                
        input.selectProviderTapped
            .withLatestFrom(selectedProvider.asDriver(onErrorJustReturn: nil))
            .ignoreNil()
            .drive(
                onNext: { [weak self] providerCell in
                    guard let self = self else {
                        return
                    }
                    let provider = providerCell.provider
                    print("selected baseUrl = \(provider.baseUrl)")
                    self.accessService.backendURL = provider.baseUrl
                    self.accessService.providerId = provider.id
                    self.accessService.providerName = provider.name
                    self.accessService.appState = .phoneNumber
                    self.apiWrapper.getPhonePattern()
                        .trackActivity(activityTracker)
                        .asDriver(onErrorJustReturn: nil)
                        .drive(
                            onNext: { [weak self] phonePattern in
                                print("phonePattern = \(String(describing: phonePattern))")
                                self?.accessService.setPhonePattern(phonePattern)
                                self?.router.trigger(.phoneNumber)
                            }
                        )
                        .disposed(by: self.disposeBag)
                    
                }
            )
            .disposed(by: disposeBag)

        input.itemStateChanged
            .withLatestFrom(self.providers.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    var (itemIndex, providers) = args
                    
                    guard let self = self, let index = itemIndex else {
                        return
                    }
                    
                    providers.enumerated().forEach { offset, _ in
                        if offset == index {
                            providers[offset].toggleState()
                        } else {
                            providers[offset].setUncheckedState()
                        }
                    }
                    
                    self.selectedProvider.onNext(providers.first { $0.state == .checkedActive })
                    
                    self.providers.onNext(providers)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            providers: providers.asDriver(onErrorJustReturn: [])
        )
    }
    
}

extension SelectProviderViewModel {
    
    struct Input {
        let inputProviderName: Driver<String?>
        let selectProviderTapped: Driver<Void>
        let itemStateChanged: Driver<Int?>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let providers: Driver<[ProviderCellModel]>
    }
    
}
