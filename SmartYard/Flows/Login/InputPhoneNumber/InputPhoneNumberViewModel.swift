//
//  InputPhoneNumberViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 05.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator

class InputPhoneNumberViewModel: BaseViewModel {
    
    private let accessService: AccessService
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<AppRoute>
    
    init(accessService: AccessService, apiWrapper: APIWrapper, router: WeakRouter<AppRoute>) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.router = router
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let tempPhoneSubject = BehaviorSubject<String?>(value: nil)
        let tempPhone = tempPhoneSubject.asDriver(onErrorJustReturn: nil)
        
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    let nsError = error as NSError
                    
                    switch nsError.code {
                    case 429:
                        let message = "Вы запрашиваете код слишком часто. Пожалуйста, попробуйте позже"
                        self?.router.trigger(.alert(title: "Ошибка", message: message))
                        
                    default:
                        self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    }
                }
            )
            .disposed(by: disposeBag)
        
        let prepareTransitionTrigger = PublishSubject<Void>()
        
        input.inputPhoneText
            .distinctUntilChanged()
            .filter { $0.count == Constants.phoneLengthWithoutPrefix }
            .do(
                onNext: { phone in
                    tempPhoneSubject.onNext(phone)
                }
            )
            .flatMapLatest { [weak self] phone -> Driver<Void?> in
                guard let self = self else {
                    return .just(nil)
                }

                return self.apiWrapper.requestCode(userPhone: "8" + phone)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .withLatestFrom(tempPhone)
            .ignoreNil()
            .do(
                onNext: { [weak self] phoneNumber in
                    self?.accessService.appState = .smsCode(phoneNumber: phoneNumber)
                    
                    prepareTransitionTrigger.onNext(())
                }
            )
            .delay(.milliseconds(100))
            .drive(
                onNext: { [weak self] phone in
                    self?.router.trigger(.pinCode(phoneNumber: phone, isInitial: true))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            prepareTransitionTrigger: prepareTransitionTrigger.asDriverOnErrorJustComplete()
        )
    }
    
}

extension InputPhoneNumberViewModel {
    
    struct Input {
        let inputPhoneText: Driver<String>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let prepareTransitionTrigger: Driver<Void>
    }
    
}
