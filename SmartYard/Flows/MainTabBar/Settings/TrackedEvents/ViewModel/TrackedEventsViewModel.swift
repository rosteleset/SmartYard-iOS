//
//  TrackedEventsViewModel.swift
//  SmartYard
//
//  Created by Александр Попов on 29.05.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import RxCocoa
import RxSwift
import XCoordinator

final class TrackedEventsViewModel: BaseViewModel {
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<SettingsRoute>
    private let flatId: Int
    private let address: String

    private let events = BehaviorRelay<[APITrackedEvent]>(value: [])

    init(
        apiWrapper: APIWrapper,
        router: WeakRouter<SettingsRoute>,
        flatId: Int,
        address: String
    ) {
        self.apiWrapper = apiWrapper
        self.router = router
        self.flatId = flatId
        self.address = address
    }

    func transform(_ input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()

        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(
                        .alert(
                            title: L10n.Common.error,
                            message: error.localizedDescription
                        )
                    )
                }
            )
            .disposed(by: disposeBag)

        input.viewWillAppearTrigger
            .flatMapLatest { [weak self] _ -> Driver<[APITrackedEvent]?> in
                guard let self else { return .empty() }

                return self.apiWrapper
                    .getTrackedEvents(flatId: self.flatId)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .map { $0 ?? [] }
            .drive(
                onNext: { [weak self] events in
                    self?.events.accept(events)
                }
            )
            .disposed(by: disposeBag)

        input.deleteTrigger
            .flatMapLatest { [weak self] event -> Driver<Int?> in
                guard let self else { return .empty() }

                return self.apiWrapper
                    .untrackEvent(watcherId: event.watcherId)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .map { _ in event.watcherId }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] watcherId in
                    guard let self else { return }

                    events.accept(events.value.filter { $0.watcherId != watcherId })
                }
            )
            .disposed(by: disposeBag)

        bindEditTrigger(
            input.editTrigger,
            activityTracker: activityTracker,
            errorTracker: errorTracker
        )

        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)

        input.addTrigger
            .drive(
                onNext: { [weak self] in
                    guard let self else { return }

                    self.router.trigger(
                        .trackedEventsHistory(
                            flatId: self.flatId,
                            address: self.address
                        )
                    )
                }
            )
            .disposed(by: disposeBag)

        return Output(
            address: .just(address),
            events: events.asDriverOnErrorJustComplete(),
            isLoading: activityTracker.asDriver()
        )
    }
}

private extension TrackedEventsViewModel {
    func bindEditTrigger(
        _ trigger: Driver<(APITrackedEvent, String)>,
        activityTracker: ActivityTracker,
        errorTracker: ErrorTracker
    ) {
        trigger
            .flatMapLatest { [weak self] event, comments -> Driver<APITrackedEvent?> in
                guard let self else { return .empty() }

                return self.apiWrapper
                    .untrackEvent(watcherId: event.watcherId)
                    .flatMap { [apiWrapper] _ in
                        apiWrapper.trackEvent(
                            flatId: event.flatId,
                            eventType: event.eventType,
                            eventDetail: event.normalizedEventDetail,
                            comments: comments
                        )
                    }
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .map { response -> APITrackedEvent? in
                        guard let watcherId = response?.watcherId else { return nil }
                        return APITrackedEvent(
                            watcherId: watcherId,
                            flatId: event.flatId,
                            eventType: event.eventType,
                            eventDetail: event.normalizedEventDetail,
                            comments: comments
                        )
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] updatedEvent in
                    guard let self else { return }

                    events.accept(
                        events.value.map {
                            $0.key == updatedEvent.key ? updatedEvent : $0
                        }
                    )
                }
            )
            .disposed(by: disposeBag)
    }
}

extension TrackedEventsViewModel {
    struct Input {
        let viewWillAppearTrigger: Driver<Void>
        let backTrigger: Driver<Void>
        let addTrigger: Driver<Void>
        let deleteTrigger: Driver<APITrackedEvent>
        let editTrigger: Driver<(APITrackedEvent, String)>
    }

    struct Output {
        let address: Driver<String>
        let events: Driver<[APITrackedEvent]>
        let isLoading: Driver<Bool>
    }
}
