//
//  EditNameViewModel.swift
//  SmartYard
//
//  Created by admin on 27/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class EditNameViewModel: BaseViewModel {
    
    private let accessService: AccessService
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<SettingsRoute>
    
    init(accessService: AccessService, apiWrapper: APIWrapper, router: WeakRouter<SettingsRoute>) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.router = router
    }
    
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let prepareTransitionTrigger = PublishSubject<Void>()
        
        let isAbleToSave = input.name
            .map { !($0?.trimmed).isNilOrEmpty }
        
        input.dismissTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        input.saveTrigger
            .withLatestFrom(input.name)
            .withLatestFrom(input.middleName) { ($0, $1) }
            .flatMap { name, middleName -> Driver<(String, String?)> in
                guard let unwrappedName = name else {
                    return .empty()
                }
                
                return .just((unwrappedName.trimmed, middleName?.trimmed))
            }
            .flatMapLatest { [weak self] args -> Driver<APIClientName?> in
                guard let self = self else {
                    return .just(nil)
                }
                
                let (name, patronymic) = args
                
                return self.apiWrapper.sendName(name: name, patronymic: patronymic)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .map { _ in APIClientName(name: name, patronymic: patronymic) }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .do(
                onNext: { [weak self] name in
                    self?.accessService.clientName = name
                    
                    NotificationCenter.default.post(
                        name: .userNameUpdated,
                        object: nil,
                        userInfo: nil
                    )
                    
                    prepareTransitionTrigger.onNext(())
                }
            )
            .delay(.milliseconds(100))
            .drive(
                onNext: { [weak self] _ in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isAbleToSave: isAbleToSave,
            isLoading: activityTracker.asDriver(),
            prepareTransitionTrigger: prepareTransitionTrigger.asDriverOnErrorJustComplete()
        )
    }
    
}

extension EditNameViewModel {
    
    struct Input {
        let name: Driver<String?>
        let middleName: Driver<String?>
        let dismissTrigger: Driver<Void>
        let saveTrigger: Driver<Void>
    }
    
    struct Output {
        let isAbleToSave: Driver<Bool>
        let isLoading: Driver<Bool>
        let prepareTransitionTrigger: Driver<Void>
    }
    
}
