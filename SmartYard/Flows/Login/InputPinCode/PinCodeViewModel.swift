//
//  PinCodeViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator
import FirebaseMessaging

final class PinCodeViewModel: BaseViewModel {
    
    private let accessService: AccessService
    private let alertService: AlertService
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<AppRoute>
    
    private let phoneNumber: String
    
    init(
        accessService: AccessService,
        alertService: AlertService,
        apiWrapper: APIWrapper,
        router: WeakRouter<AppRoute>,
        phoneNumber: String
    ) {
        self.accessService = accessService
        self.alertService = alertService
        self.apiWrapper = apiWrapper
        self.router = router
        self.phoneNumber = phoneNumber
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let isPinCorrect = BehaviorSubject<Bool>(value: true)
        let prepareTransitionTrigger = PublishSubject<Void>()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.logAuthCodeConfirmationFailed(error)
                    let nsError = error as NSError
                    
                    switch nsError.code {
                    case 403:
                        isPinCorrect.onNext(false)
                        
                    case 429:
                        let message = L10n.Auth.CodeRateLimit.message
                        self?.router.trigger(
                            .alert(
                                title: L10n.Common.error,
                                message: message
                            )
                        )
                        
                    default:
                        self?.router.trigger(
                            .alert(
                                title: L10n.Common.error,
                                message: error.localizedDescription
                            )
                        )
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
                guard let self else { return .just(nil) }

                return self.apiWrapper.confirmCode(
                    userPhone: AccessService.shared.phonePrefix + phoneNumber,
                    smsCode: smsCode
                )
                .trackActivity(activityTracker)
                .trackError(errorTracker)
                .asObservable()
                .catch { [weak self] error -> Observable<ConfirmCodeResponseData?> in
                    guard let self else { return .just(nil) }
                    let nsError = error as NSError

                    if nsError.code == 403 {
                        let okAction = UIAlertAction(
                            title: L10n.Common.ok,
                            style: .default,
                            handler: { [weak self] _ in
                                self?.router.trigger(.phoneNumber)
                            }
                        )

                        self.alertService.showDialog(
                            title: L10n.Common.error,
                            message: nsError.localizedDescription,
                            preferredStyle: .alert,
                            actions: [okAction],
                            priority: 250
                        )
                    }

                    return .just(nil)
                }
                .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .do(
                onNext: { [weak self] data in
                    guard let self else { return }

                    logAuthConfirmed()

                    accessService.authorizeSession(
                        token: data.accessToken,
                        name: data.name,
                        phone: phoneNumber
                    )
                    accessService.appState = .userName

                    // TODO: - подумать куда засунуть messaging
                    Messaging.messaging().isAutoInitEnabled = true

                    prepareTransitionTrigger.onNext(())
                }
            )
            .delay(.milliseconds(100))
            .drive(
                onNext: { [weak self] data in
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
        
        input.backButtonTapped
            .drive(
                onNext: { [weak self] in
                    self?.accessService.appState = .phoneNumber
                    
                    self?.router.trigger(.phoneNumber)
                }
            )
            .disposed(by: disposeBag)
        
        input.sendCodeAgainButtonTapped
            .do(
                onNext: { [weak self] in
                    self?.logAuthCodeRequested(source: "pin_code_resend")
                }
            )
            .flatMapLatest { [weak self] _ -> Driver<RequestCodeResponseData?> in
                guard let self else { return .empty() }

                return self.apiWrapper.requestCode(userPhone: AccessService.shared.phonePrefix + self.phoneNumber)
                    .do(
                        onError: { [weak self] error in
                            self?.logAuthCodeRequestFailed(error, source: "pin_code_resend")
                        }
                    )
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .do(
                onNext: { [weak self] _ in
                    self?.logAuthCodeRequestSuccess(source: "pin_code_resend")
                }
            )
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

private extension PinCodeViewModel {

    func logAuthConfirmed() {
        AppAnalytics.log(AppAnalyticsEvent.authCodeConfirmed(source: "pin_code"))
        AppAnalytics.log(AppAnalyticsEvent.authSuccess(source: "pin_code"))
    }

    func logAuthCodeRequested(source: String) {
        AppAnalytics.log(AppAnalyticsEvent.authCodeRequested(source: source))
    }

    func logAuthCodeRequestSuccess(source: String) {
        AppAnalytics.log(AppAnalyticsEvent.authCodeRequestSuccess(source: source))
    }

    func logAuthCodeRequestFailed(_ error: Error, source: String) {
        AppAnalytics.log(
            AppAnalyticsEvent.authCodeRequestFailed(
                source: source,
                errorCode: AnalyticsError.code(from: error),
                safeMessage: AnalyticsError.safeMessage(from: error)
            )
        )
    }

    func logAuthCodeConfirmationFailed(_ error: Error) {
        AppAnalytics.log(
            AppAnalyticsEvent.authCodeConfirmationFailed(
                source: "pin_code",
                errorCode: AnalyticsError.code(from: error),
                safeMessage: AnalyticsError.safeMessage(from: error)
            )
        )
    }
}

extension PinCodeViewModel {
    
    struct Input {
        let inputPinText: Driver<String>
        let fixPhoneNumberButtonTapped: Driver<Void>
        let backButtonTapped: Driver<Void>
        let sendCodeAgainButtonTapped: Driver<Void>
    }
    
    struct Output {
        let isPinCorrect: Driver<Bool>
        let phoneNumber: Driver<String>
        let isLoading: Driver<Bool>
        let prepareTransitionTrigger: Driver<Void>
    }
    
}
