//
//  InputPhoneNumberViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 05.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator

class InputPhoneNumberViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<AppRoute>
    
    init(apiWrapper: APIWrapper, router: WeakRouter<AppRoute>) {
        self.apiWrapper = apiWrapper
        self.router = router
    }
    
    func transform(input: Input) -> Output {
        let tempPhoneSubject = BehaviorSubject<String?>(value: nil)
        let tempPhone = tempPhoneSubject.asDriver(onErrorJustReturn: nil)
        
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
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
            .drive(
                onNext: { [weak self] phone in
                    self?.router.trigger(.pinCode(phoneNumber: phone))
                }
            )
            .disposed(by: disposeBag)
        
        errorTracker.asDriver()
            .drive(
                onNext: { error in
                    print(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(isLoading: activityTracker.asDriver())
    }
    
}

extension InputPhoneNumberViewModel {
    
    struct Input {
        let inputPhoneText: Driver<String>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
    }
    
}
