//
//  UserNameViewModel.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class UserNameViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<AppRoute>
    
    init(apiWrapper: APIWrapper, router: WeakRouter<AppRoute>) {
        self.apiWrapper = apiWrapper
        self.router = router
    }
    
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let prepareTransitionTrigger = PublishSubject<Void>()
        
        let isAbleToContinue = input.name
            .map { !$0.isNilOrEmpty }
        
        input.continueTrigger
            .withLatestFrom(input.name)
            .withLatestFrom(input.middleName) { ($0, $1) }
            .flatMap { name, middleName -> Driver<(String, String?)> in
                guard let unwrappedName = name else {
                    return .empty()
                }
                
                return .just((unwrappedName, middleName))
            }
            .flatMapLatest { [weak self] args -> Driver<Void?> in
                guard let self = self else {
                    return .just(nil)
                }
                
                let (name, patronymic) = args
                
                return self.apiWrapper.sendName(name: name, patronymic: patronymic)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .do(
                onNext: { _ in
                    prepareTransitionTrigger.onNext(())
                }
            )
            .delay(.milliseconds(100))
            .drive(
                onNext: { [weak self] _ in
                    self?.router.trigger(.main)
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
        
        return Output(
            isAbleToContinue: isAbleToContinue,
            isLoading: activityTracker.asDriver(),
            prepareTransitionTrigger: prepareTransitionTrigger.asDriverOnErrorJustComplete()
        )
    }
    
}

extension UserNameViewModel {
    
    struct Input {
        let name: Driver<String?>
        let middleName: Driver<String?>
        let continueTrigger: Driver<Void>
    }
    
    struct Output {
        let isAbleToContinue: Driver<Bool>
        let isLoading: Driver<Bool>
        let prepareTransitionTrigger: Driver<Void>
    }
    
}
