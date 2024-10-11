//
//  SendDetailsViewModel.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 26.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class SendDetailsViewModel: BaseViewModel {
    
    private let accessService: AccessService
    private let apiWrapper: APIWrapper
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    private let router: WeakRouter<HomePayRoute>
    
    init(
        accessService: AccessService,
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        router: WeakRouter<HomePayRoute>
    ) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.router = router
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let isAbleToSend = Driver
            .combineLatest(
                input.email,
                input.range
            )
            .map { args -> Bool in
                let (email, range) = args

                guard let uEmail = email?.trimmed, !uEmail.isEmpty, self.isValidEmail(uEmail),
                      let fromDay = range?.fromDay,
                      let toDay = range?.toDay else {
                    return false
                }
                
                return true
            }

        // MARK: Закрытие экрана
        
        input.dismissTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Отправка детализации на указанный email
        
        input.sendTrigger
            .withLatestFrom(input.email)
            .withLatestFrom(input.range) { ($0, $1) }
            .flatMapLatest { [weak self] email, range -> Driver<Void?> in
                guard let self = self, let uEmail = email?.trimmed, !uEmail.isEmpty, self.isValidEmail(uEmail),
                      let fromDay = range?.fromDay,
                      let toDay = range?.toDay,
                      let contract = range?.contract else {
                    return .just(nil)
                }
                
                let formatter = DateFormatter()

                formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
                formatter.dateFormat = "dd.MM.yyyy"
                
                return self.apiWrapper
                    .sendBalanceDetails(
                        id: contract.clientId,
                        contract: contract.contractName,
                        to: formatter.string(from: toDay),
                        from: formatter.string(from: fromDay),
                        mail: uEmail
                    )
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isAbleToSend: isAbleToSend,
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension SendDetailsViewModel {
    
    struct Input {
        let range: Driver<DetailRange?>
        let email: Driver<String?>
        let dismissTrigger: Driver<Void>
        let sendTrigger: Driver<Void>
    }
    
    struct Output {
        let isAbleToSend: Driver<Bool>
        let isLoading: Driver<Bool>
    }
    
}
