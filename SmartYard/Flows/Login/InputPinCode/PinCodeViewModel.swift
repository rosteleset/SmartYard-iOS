//
//  PinCodeViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import Foundation
import RxCocoa
import RxSwift
import XCoordinator
import FirebaseCrashlytics

class PinCodeViewModel: BaseViewModel {
    
    private let accessService: AccessService
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<AppRoute>
    
    private let phoneNumber: String
    
    init(accessService: AccessService, apiWrapper: APIWrapper, router: WeakRouter<AppRoute>, phoneNumber: String) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.router = router
        self.phoneNumber = phoneNumber
    }
    
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let isPinCorrect = BehaviorSubject<Bool>(value: true)
        let prepareTransitionTrigger = PublishSubject<Void>()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    let nsError = error as NSError
                    
                    switch nsError.code {
                    case 403:
                        isPinCorrect.onNext(false)
                        
                    case 429:
                        let message = "Вы запрашиваете код слишком часто. Пожалуйста, попробуйте позже"
                        self?.router.trigger(.alert(title: "Ошибка", message: message))
                        
                    default:
                        self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    }
                }
            )
            .disposed(by: disposeBag)
        
        input.inputPinText
            .distinctUntilChanged()
            .do(
                onNext: { _ in
                    isPinCorrect.onNext(true)
                }
            )
            .filter { $0.count == Constants.pinLength }
            .flatMapLatest { [weak self] smsCode -> Driver<ConfirmCodeResponseData?> in
                guard let self = self else {
                    return .just(nil)
                }
                
                return self.apiWrapper.confirmCode(userPhone: "8" + self.phoneNumber, smsCode: smsCode)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .do(
                onNext: { [weak self] data in
                    self?.accessService.accessToken = data.accessToken
                    self?.accessService.clientName = data.name
                    self?.accessService.clientPhoneNumber = self?.phoneNumber
                    self?.accessService.appState = .userName
                    
                    // когда пользователь авторизовался уже после инициализации Crashlytics, то надо обновить  UserId
                    Crashlytics.crashlytics().setUserID(self?.accessService.clientPhoneNumber ?? "unknown")
                    
                    prepareTransitionTrigger.onNext(())
                }
            )
            .delay(.milliseconds(100))
            .do(
                onNext: { [weak self] data in
                    
                    self?.apiWrapper.checkAppVersion()
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
                        .ignoreNil()
                        .drive(
                            onNext: { _ in
                            }
                        )
                        .disposed(by: self!.disposeBag)
                }
            )
            .delay(.milliseconds(100))
            .drive(
                onNext: { [weak self] data in
                    
                    self?.apiWrapper.getOptions()
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
                        .ignoreNil()
                        .drive(
                            onNext: { [weak self] result in
                                self?.accessService.paymentsUrl = result.paymentsUrl ?? ""
                                self?.accessService.supportPhone = result.supportPhone ?? ""
                                self?.accessService.centraScreenUrl = result.centraScreenUrl ?? ""
                                self?.accessService.intercomScreenUrl = result.intercomScreenUrl ?? ""
                                self?.accessService.activeTab = result.activeTab ?? "centra"
                            }
                        )
                        .disposed(by: self!.disposeBag)

                    self?.router.trigger(.userName(preloadedName: data.name))
                }
            )
            .disposed(by: disposeBag)
        
        input.fixPhoneNumberButtonTapped
            .drive(
                onNext: { [weak self] in
                    self?.accessService.appState = .phoneNumber
                    
                    self?.router.trigger(.phoneNumber)
                }
            )
            .disposed(by: disposeBag)
        
        input.sendCodeAgainButtonTapped
            .flatMapLatest { [weak self] _ -> Driver<RequestCodeResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.requestCode(userPhone: "8" + self.phoneNumber)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive()
            .disposed(by: disposeBag)
        
        return Output(
            isPinCorrect: isPinCorrect.asDriverOnErrorJustComplete(),
            phoneNumber: .just(phoneNumber),
            isLoading: activityTracker.asDriver(),
            prepareTransitionTrigger: prepareTransitionTrigger.asDriverOnErrorJustComplete()
        )
    }
    
}

extension PinCodeViewModel {
    
    struct Input {
        let inputPinText: Driver<String>
        let fixPhoneNumberButtonTapped: Driver<Void>
        let sendCodeAgainButtonTapped: Driver<Void>
    }
    
    struct Output {
        let isPinCorrect: Driver<Bool>
        let phoneNumber: Driver<String>
        let isLoading: Driver<Bool>
        let prepareTransitionTrigger: Driver<Void>
    }
    
}
// swiftlint:enable function_body_length
