//
//  NewAllowedCarViewModel.swift
//  SmartYard
//
//  Created by Александр Попов on 09.07.2025.
//  Copyright © 2025 Sesameware. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator

protocol NewAllowedCarViewModelDelegate: AnyObject {
    func newAllowedCarViewModel(
        _ viewModel: NewAllowedCarViewModel, save car: AllowedCar,
        trackingEnabled: Bool, replacing original: AllowedCar?
    ) -> Single<LicensePlateSaveResult>
}

final class NewAllowedCarViewModel: BaseViewModel {
    private let router: WeakRouter<SettingsRoute>
    private let apiWrapper: APIWrapper
    private let logoutHelper: LogoutHelper
    private weak var delegate: NewAllowedCarViewModelDelegate?
    private let activityTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()
    private let hasSaved = BehaviorRelay(value: false)

    let originalCar: AllowedCar?
    var supportsTimedAccess: Bool { apiWrapper.accessService.lprsVersion == .timed }
    var supportsTracking: Bool { supportsTimedAccess && apiWrapper.accessService.eventsTrackingEnabled }
    var timeZone: TimeZone { TimeZone(identifier: apiWrapper.accessService.timeZone) ?? .current }

    init(
        router: WeakRouter<SettingsRoute>, delegate: NewAllowedCarViewModelDelegate,
        apiWrapper: APIWrapper, logoutHelper: LogoutHelper, originalCar: AllowedCar? = nil
    ) {
        self.router = router
        self.delegate = delegate
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.originalCar = originalCar
        super.init()
    }

    func transform(_ input: Input) -> Output {
        errorTracker.asDriver()
            .catchAuthorizationError { [weak self] in
                guard let self else { return }
                self.logoutHelper.showAuthErrorAlert(
                    activityTracker: self.activityTracker,
                    errorTracker: self.errorTracker, disposeBag: self.disposeBag
                )
            }
            .ignoreNil()
            .drive(with: self) { owner, error in
                owner.router.trigger(.alert(title: L10n.Common.error, message: error.localizedDescription))
            }
            .disposed(by: disposeBag)

        let formatsUnavailable = BehaviorRelay(value: false)
        let formats: Driver<[APILicensePlateFormat]?> = supportsTimedAccess
            ? input.retryFormatsTrigger.startWith(())
                .flatMapLatest { [weak self] _ -> Driver<[APILicensePlateFormat]?> in
                    guard let self else { return .empty() }
                    return self.apiWrapper.getLicensePlateFormats()
                        .map { Optional($0) }
                        .trackError(self.errorTracker)
                        .asDriver(onErrorJustReturn: nil)
                        .do(onNext: { formatsUnavailable.accept($0?.isEmpty ?? true) })
                }
                .startWith(nil)
            : .just([])

        let unsupportedNumber = Driver.combineLatest(input.car, formats)
            .map { [weak self] car, formats in
                guard let self, self.supportsTimedAccess, let car, let formats, !formats.isEmpty else { return false }
                return !formats.contains {
                    $0.countryCode.lowercased() == car.countryCode && $0.matches(car.apiNumber)
                }
            }

        let canConfirm = Driver.combineLatest(input.car, formats, activityTracker.asDriver(), hasSaved.asDriver())
            .map { [weak self] car, formats, loading, saved in
                guard let self, let car, car.validity.isValid, !loading, !saved else { return false }
                guard self.supportsTimedAccess else { return true }
                return formats?.contains {
                    $0.countryCode.lowercased() == car.countryCode && $0.matches(car.apiNumber)
                } ?? false
            }
            .distinctUntilChanged()

        input.closeTrigger.withLatestFrom(activityTracker.asDriver())
            .filter { !$0 }
            .drive(with: self) { owner, _ in owner.router.trigger(.dismiss) }
            .disposed(by: disposeBag)

        let draft = Driver.combineLatest(input.car, input.trackingEnabled, canConfirm)
        input.addAccessTrigger.withLatestFrom(draft)
            .asObservable()
            .flatMapFirst { [weak self] car, tracking, allowed -> Observable<LicensePlateSaveResult> in
                guard let self, let car, allowed, let delegate = self.delegate else { return .empty() }
                return delegate.newAllowedCarViewModel(
                    self, save: car, trackingEnabled: tracking, replacing: self.originalCar
                )
                .trackActivity(self.activityTracker)
                .trackError(self.errorTracker)
                .catch { _ in .empty() }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, result in
                owner.hasSaved.accept(true)
                owner.router.trigger(.dismiss) {
                    guard let warning = result.warning else { return }
                    owner.router.trigger(.alert(title: L10n.Settings.VehiclePass.savedTitle, message: warning))
                }
            }
            .disposed(by: disposeBag)

        return Output(
            canConfirm: canConfirm, isLoading: activityTracker.asDriver(),
            formatsUnavailable: formatsUnavailable.asDriver(), unsupportedNumber: unsupportedNumber
        )
    }
}

extension NewAllowedCarViewModel {
    struct Input {
        let closeTrigger: Driver<Void>
        let car: Driver<AllowedCar?>
        let trackingEnabled: Driver<Bool>
        let addAccessTrigger: Driver<Void>
        let retryFormatsTrigger: Driver<Void>
    }

    struct Output {
        let canConfirm: Driver<Bool>
        let isLoading: Driver<Bool>
        let formatsUnavailable: Driver<Bool>
        let unsupportedNumber: Driver<Bool>
    }
}
