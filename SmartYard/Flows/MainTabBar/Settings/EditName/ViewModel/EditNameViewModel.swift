//
//  EditNameViewModel.swift
//  SmartYard
//
//  Created by admin on 27/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class EditNameViewModel: BaseViewModel {
    
    private let accessService: AccessService
    private let apiWrapper: APIWrapper
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    private let router: WeakRouter<SettingsRoute>
    
    init(
        accessService: AccessService,
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        router: WeakRouter<SettingsRoute>
    ) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.router = router
    }
    
    // swiftlint:disable:next function_body_length
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
                    self?.router.trigger(.alert(
                        title: NSLocalizedString("Error", comment: ""),
                        message: error.localizedDescription
                    ))
                }
            )
            .disposed(by: disposeBag)
        
        let prepareTransitionTrigger = PublishSubject<Void>()
        
        let isAbleToSave = input.name
            .map { !($0?.trimmed).isNilOrEmpty }
        
        // MARK: Закрытие экрана
        
        input.dismissTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Сохранение введенного имени / отчества
        
        input.saveTrigger
            .withLatestFrom(input.name)
            .withLatestFrom(input.middleName) { ($0, $1) }
            .flatMapLatest { [weak self] name, middleName -> Driver<APIClientName?> in
                guard let self = self, let unwrappedName = name?.trimmed, !unwrappedName.isEmpty else {
                    return .empty()
                }
                
                return self.apiWrapper.sendName(name: unwrappedName, patronymic: middleName?.trimmed)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .map { _ in APIClientName(name: unwrappedName, patronymic: middleName?.trimmed) }
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
