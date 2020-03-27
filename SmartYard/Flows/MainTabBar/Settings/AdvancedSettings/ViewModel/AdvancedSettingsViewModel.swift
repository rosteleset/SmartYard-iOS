//
//  AdvancedSettingsViewModel.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxCocoa
import RxSwift
import XCoordinator

class AdvancedSettingsViewModel: BaseViewModel {
    
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let router: WeakRouter<SettingsRoute>
    
    init(
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        router: WeakRouter<SettingsRoute>,
        name: String
    ) {
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.router = router
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let currentName = BehaviorSubject<APIClientName?>(value: accessService.clientName)
        
        let nameAsString = currentName
            .asDriver(onErrorJustReturn: nil)
            .map { clientName in
                [clientName?.name, clientName?.patronymic]
                    .compactMap { $0 }
                    .joined(separator: " ")
            }
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        input.logoutTrigger
            .drive(
                onNext: { [weak self] in
                    let noAction = UIAlertAction(title: "Нет", style: .cancel, handler: nil)
                    
                    let yesAction = UIAlertAction(title: "Да", style: .destructive) { _ in
                        guard let self = self else {
                            return
                        }
                        
                        self.pushNotificationService.resetInstanceId()
                            .trackActivity(activityTracker)
                            .trackError(errorTracker)
                            .asDriver(onErrorJustReturn: nil)
                            .ignoreNil()
                            .drive(
                                onNext: { [weak self] in
                                    self?.accessService.logout()
                                }
                            )
                            .disposed(by: self.disposeBag)
                    }
                    
                    self?.router.trigger(
                        .dialog(
                            title: "Выход из приложения",
                            message: "Вы действительно хотите выйти из вашей учетной записи?",
                            actions: [noAction, yesAction]
                        )
                    )
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
            name: nameAsString,
            enableNotifications: .just(true),
            enableText: .just(true),
            ringtone: .just("Нота"),
            enableAccountBalanceWarning: .just(false),
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension AdvancedSettingsViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let logoutTrigger: Driver<Void>
    }
    
    struct Output {
        let name: Driver<String>
        let enableNotifications: Driver<Bool>
        let enableText: Driver<Bool>
        let ringtone: Driver<String>
        let enableAccountBalanceWarning: Driver<Bool>
        let isLoading: Driver<Bool>
    }
    
}
