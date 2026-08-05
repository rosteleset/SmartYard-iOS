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

final class InputPhoneNumberViewModel: BaseViewModel {
    
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
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.logAuthCodeRequestFailed(error)
                    let nsError = error as NSError
                    
                    switch nsError.code {
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
        
        let prepareTransitionTrigger = PublishSubject<Void>()
        
        input.inputPhoneText
            .distinctUntilChanged()
            .filter { $0.count == AccessService.shared.phoneLengthWithoutPrefix }
            .do(
                onNext: { [weak self] _ in
                    self?.logPhoneEnteredAndCodeRequested()
                }
            )
            .flatMapLatest { [weak self] phone -> Driver<(RequestCodeResponseData, String)?> in
                guard let self = self else {
                    return .just(nil)
                }

                return self.apiWrapper.requestCode(userPhone: AccessService.shared.phonePrefix + phone)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .map { response in
                        guard let response = response else {
                            return nil
                        }

                        return (response, phone)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .do(
                onNext: { [weak self] response, phoneNumber in
                    guard let self = self else {
                        return
                    }

                    self.logAuthCodeRequestSuccess()

                    let transition = self.authTransition(for: response, phoneNumber: phoneNumber)
                    self.accessService.appState = transition.appState

                    if !transition.shouldPrepare {
                        return
                    }
                    
                    prepareTransitionTrigger.onNext(())
                }
            )
            .delay(.milliseconds(100))
            .drive(
                onNext: { [weak self] response, phone in
                    guard let self = self else {
                        return
                    }
                    
                    self.triggerAuthRoute(for: response, phone: phone)
                }
            )
            .disposed(by: disposeBag)
    
        input.backButtonTapped
            .drive(
                onNext: { [weak self] in
                    self?.accessService.appState = .selectProvider
                    
                    self?.router.trigger(.selectProvider)
                }
            )
            .disposed(by: disposeBag)
            
        input.fixProviderButtonTapped
            .drive(
                onNext: { [weak self] in
                    self?.accessService.appState = .selectProvider
                    
                    self?.router.trigger(.selectProvider)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            prepareTransitionTrigger: prepareTransitionTrigger.asDriverOnErrorJustComplete(),
            selectedProviderName: .just(accessService.provider.name)
        )
    }
    
}

private extension InputPhoneNumberViewModel {

    func authTransition(
        for response: RequestCodeResponseData,
        phoneNumber: String
    ) -> (appState: AppState, shouldPrepare: Bool) {
        switch response {
        case .outgoingCall(let confirmNumbers):
            guard let confirmNumber = confirmNumbers.first else {
                return (.smsCode(phoneNumber: phoneNumber), false)
            }

            return (
                .authByOutgoingCall(
                    phoneNumber: phoneNumber,
                    confirmPhoneNumber: confirmNumber
                ),
                true
            )
        case .flashCall:
            return (.flashCall(phoneNumber: phoneNumber), true)
        case .otp:
            return (.smsCode(phoneNumber: phoneNumber), true)
        }
    }

    func triggerAuthRoute(for response: RequestCodeResponseData, phone: String) {
        switch response {
        case .outgoingCall(let confirmNumbers):
            guard let confirmNumber = confirmNumbers.first else {
                router.trigger(.alert(
                    title: L10n.Common.error,
                    message: L10n.Auth.PhoneEntry.Error.confirmationNumberMissing
                ))
                return
            }

            router.trigger(
                .authByOutgoingCall(
                    phoneNumber: phone,
                    confirmPhoneNumber: confirmNumber
                )
            )
        case .flashCall:
            router.trigger(
                .pinCode(
                    phoneNumber: phone,
                    isInitial: true,
                    useFlashCall: true
                )
            )
        case .otp:
            router.trigger(
                .pinCode(
                    phoneNumber: phone,
                    isInitial: true,
                    useFlashCall: false
                )
            )
        }
    }

    func logPhoneEnteredAndCodeRequested() {
        AppAnalytics.log(AppAnalyticsEvent.authPhoneEntered(source: "phone_entry"))
        AppAnalytics.log(AppAnalyticsEvent.authCodeRequested(source: "phone_entry"))
    }

    func logAuthCodeRequestSuccess() {
        AppAnalytics.log(AppAnalyticsEvent.authCodeRequestSuccess(source: "phone_entry"))
    }

    func logAuthCodeRequestFailed(_ error: Error) {
        AppAnalytics.log(
            AppAnalyticsEvent.authCodeRequestFailed(
                source: "phone_entry",
                errorCode: AnalyticsError.code(from: error),
                safeMessage: AnalyticsError.safeMessage(from: error)
            )
        )
    }
}

extension InputPhoneNumberViewModel {
    
    struct Input {
        let inputPhoneText: Driver<String>
        let backButtonTapped: Driver<Void>
        let fixProviderButtonTapped: Driver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let prepareTransitionTrigger: Driver<Void>
        let selectedProviderName: Driver<String>
    }
    
}
