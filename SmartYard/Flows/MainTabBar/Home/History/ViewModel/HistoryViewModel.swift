//
//  YardMapViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import CoreLocation
import RxDataSources

typealias FlatId = Int
typealias AvailableDays = [FlatId: PlogDaysResponseData] // [FlatId: [APIPlogDay]]

final class HistoryViewModel: BaseViewModel {

    let apiWrapper: APIWrapper
    let router: WeakRouter<HistoryRoute>

    let errorTracker = ErrorTracker()
    let activityTracker = ActivityTracker()
    let availableDaysForFlat = PublishSubject<AvailableDays>()
    let updateSections = PublishSubject<Void>()
    let updateAvailableDays = PublishSubject<Bool>()

    /// идентификатор дома для какого смотрим логи
    let houseId: String?
    let flatId: Int?

    /// Адрес этого дома
    private let address: BehaviorSubject<String?>

    /// список доступных квартир по адресу на сервере
    var flatIds: [Int] = []

    /// список номеров доступных квартир по адресу на сервере
    var flatNumbers: [Int] = []

    /// признак того, надо ли отключать получение ответов из кеша сервера.
    var forceRefresh = false

    /// массив из квартир с массивом дат, доступных для каждой с учётом текущих фильтров
    var availableDays: AvailableDays = [:]

    /// массив из квартир с массивом дат, доступных для каждой с учётом текущих фильтров
    let availableDaysSubject = BehaviorSubject<AvailableDays>(value: [:])

    /// облегчённая версия availableDays - массив из доступных дат с учётом текущих фильтров
    var uniqueDays: [Date] = []

    /// Очередь активных запросов на загрузку (FlatId, Date)
    /// - запросы по которым мы уже ожидаем данные и повторно их не запрашиваем
    var loadingQueue: [(flatId: Int, day: Date)] = []

    /// сюда прилетают результаты запросов с API: один элемент - один день для одной квартиры
    let logs = PublishSubject<DayFlatItemsData>()

    /// все загруженные данные от API
    var dataCache: [DayFlatItemsData] = []

    /// данные для отображения в виде готовых секций для dataSource с учётом текущих фильтров
    let sections = BehaviorRelay<[HistorySectionModel]>(value: [])

    /// фильтр по типам событий
    let eventsFilter = BehaviorRelay<EventsFilter>(value: .all)

    /// фильтр по квартирам
    let apptsFilter = BehaviorRelay<[Int]>(value: [])

    /// таблица соответствия objectId <-> url flussonic
    let camMap = BehaviorRelay<[APICamMap]>(value: [])

    /// таблица лиц по квартирам
    var listFaces: [FlatId: GetPersonFacesResponseData] = [:]

    /// таблица отслеживаемых событий: "\(flatId)_\(eventType)_\(eventDetail)" -> watcher.
    let trackedEvents = BehaviorRelay<[String: APITrackedEvent]>(value: [:])

    init(
        apiWrapper: APIWrapper,
        houseId: String? = nil,
        flatId: Int? = nil,
        eventsFilter: EventsFilter = .all,
        address: String,
        router: WeakRouter<HistoryRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.houseId = houseId
        self.flatId = flatId
        self.router = router
        self.address = BehaviorSubject<String?>(value: address)
        self.eventsFilter.accept(eventsFilter)

        super.init()

        bind()
    }

    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        input.refreshDataTrigger
            .do( onNext: { self.dataCache = [] })
            .mapToTrue()
            .drive(updateAvailableDays)
            .disposed(by: disposeBag)
        
        input.loadDay
            .flatMap { [weak self] day -> Driver<DayFlatItemsData?> in
                guard let self else { return .just(nil) }

                let lock = NSLock()
                
                let results = PublishSubject<DayFlatItemsData?>()
                
                // запрашиваем логи за день для каждой квартиры и результат каждого запроса отправляем,
                // как отдельный элемент в текущую последовательность
                self.apptsFilter.value.forEach { flatId in
                    // проверяем, что для этой квартиры есть записи в этот день
                    guard let days = self.availableDays[flatId],
                          days.contains( where: { $0.day == day })
                            // иначе переходим к следующей квартире.
                    else { return }

                    lock.lock()
                    let isInQueue = self.loadingQueue.first { $0.flatId == flatId && $0.day == day }
                    let isInCache = self.dataCache.first { $0.flatId == flatId && $0.day == day }
                    
                    // если мы уже запрашиваем или имеем в кеше этот элемент, то не запрашиваем его повторно
                    guard isInQueue == nil, isInCache == nil else {
                        lock.unlock()
                        return
                    }
                    
                    self.loadingQueue.append((flatId: flatId, day: day))
                    lock.unlock()
                    
                    self.apiWrapper.plog(flatId: flatId, fromDate: day, forceRefresh: self.forceRefresh)
                        .trackError(self.errorTracker)
                        .map { logs -> DayFlatItemsData? in
                            guard let logs else { return nil }
                            return DayFlatItemsData(
                                day: day,
                                items: logs.map { $0.withFallbackFlatId(flatId) },
                                flatId: flatId
                            )
                        }
                        .asDriver(onErrorJustReturn: nil)
                        .ignoreNil()
                        .drive { result in
                            results.onNext(result)
                        }
                        .disposed(by: self.disposeBag)
                }
                
                return results.asDriver(onErrorJustReturn: nil)
            }
            .trackError(errorTracker)
            .ignoreNil()
            .bind(to: self.logs)
            .disposed(by: disposeBag)
       
        input.itemSelected
            .drive(
                onNext: { [weak self] item in
                    guard let viewModel = self else { return }
                    viewModel.logEventDetailsOpened(item.value)

                    viewModel.router.trigger(
                        .detail(
                            viewModel: viewModel,
                            item: item
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
        
        input.eventsFilter
            .drive(eventsFilter)
            .disposed(by: disposeBag)
        
        input.apptsFilter
            .drive(apptsFilter)
            .disposed(by: disposeBag)
        
        return Output(
            availableDays: availableDaysSubject.asDriver(onErrorJustReturn: [:]),
            address: address.asDriverOnErrorJustComplete(),
            isLoading: activityTracker.asDriver(),
            sections: sections.asDriverOnErrorJustComplete()
        )
    }
    
    func extractFaceImage(uuid: String) -> UIImage? {
        for data in dataCache {
            if let item = data.items.first(where: { $0.uuid == uuid }) {
                return item.previewImage
            }
        }
        
        return nil
    }
    // swiftlint:disable:next function_body_length
    func transform(_ input: InputDetail) -> OutputDetail {
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        input.updateSections
            .drive(updateSections)
            .disposed(by: disposeBag)
        
        input.loadDay
            .distinctUntilChanged()
        // swiftlint:disable:next closure_body_length
            .flatMap { [weak self] day -> Driver<DayFlatItemsData?> in
                guard let self else { return .just(nil) }

                let lock = NSLock()
                
                let results = PublishSubject<DayFlatItemsData?>()
                
                // запрашиваем логи за день для каждой квартиры и результат каждого запроса отправляем,
                // как отдельный элемент в текущую последовательность
                self.apptsFilter.value.forEach { flatId in
                    // проверяем, что для этой квартиры есть записи в этот день
                    guard let days = self.availableDays[flatId],
                          days.contains(where: { $0.day == day })
                            // иначе переходим к следующей квартире.
                    else { return }

                    lock.lock()
                    let isInQueue = self.loadingQueue.first { $0.flatId == flatId && $0.day == day }
                    let isInCache = self.dataCache.first { $0.flatId == flatId && $0.day == day }
                    
                    // если мы уже запрашиваем или имеем в кеше этот элемент, то не запрашиваем его повторно
                    guard isInQueue == nil, isInCache == nil else {
                        lock.unlock()
                        return
                    }
                    
                    self.loadingQueue.append((flatId: flatId, day: day))
                    lock.unlock()
                    
                    self.apiWrapper.plog(flatId: flatId, fromDate: day, forceRefresh: self.forceRefresh)
                        .trackError(self.errorTracker)
                        .map { logs -> DayFlatItemsData? in
                            guard let logs else { return nil }
                            return DayFlatItemsData(
                                day: day,
                                items: logs.map { $0.withFallbackFlatId(flatId) },
                                flatId: flatId
                            )
                        }
                        .asDriver(onErrorJustReturn: nil)
                        .ignoreNil()
                        .drive { results.onNext($0) }
                        .disposed(by: self.disposeBag)
                }
                
                return results.asDriver(onErrorJustReturn: nil)
            }
            .trackError(errorTracker)
            .ignoreNil()
            .bind(to: self.logs)
            .disposed(by: disposeBag)
        
        input.addFaceTrigger
            .drive { [weak self] event in
                guard let self else { return }

                self.router.trigger(.addFaceFromEvent(event: event))
            }
            .disposed(by: disposeBag)
        
        input.deleteFaceTrigger
            .drive { [weak self] event in
                guard let self else { return }

                var face: APIFace?
                for faces in self.listFaces.values {
                    face = faces.first(where: { $0.faceId == Int(event.detailX?.faceId ?? "") })
                    if face != nil { break }
                }
                
                // тут не очень хорошо получается...
                // когда мы сами лезем в dataCache и меняем flags,
                // то потом у нас нет faceId в событиях по какому мы можем связать лица.
                // а пользователю надо показать лицо, какое мы будем удалять,
                // поэтому берём картинку из события за неимением ничего лучшего.

                let imageURL = face != nil ? face?.image : event.previewURL

                self.router.trigger(
                    .deleteFaceFromEvent(
                        event: event,
                        imageURL: imageURL
                    )
                )
            }
            .disposed(by: disposeBag)

        input.displayHintTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.showModal(withContent: .aboutVideoEvent))
                }
            )
            .disposed(by: disposeBag)

        bindEventTracking(input)

        bindEventUntracking(input)

        return OutputDetail(
            availableDays: availableDaysSubject.asDriver(onErrorJustReturn: [:]),
            isLoading: activityTracker.asDriver(),
            sections: sections.asDriverOnErrorJustComplete(),
            camMap: camMap.asDriverOnErrorJustComplete(),
            trackedEvents: trackedEvents.asDriverOnErrorJustComplete()
        )
    }
}

extension HistoryViewModel {
    
    struct Input {
        let itemSelected: Driver<HistoryDataItem>
        let backTrigger: Driver<Void>
        let loadDay: Driver<Date>
        let refreshDataTrigger: Driver<Void>
        let eventsFilter: Driver<EventsFilter>
        let apptsFilter: Driver<[Int]>
    }
    
    struct Output {
        let availableDays: Driver<AvailableDays>
        let address: Driver<String?>
        let isLoading: Driver<Bool>
        let sections: Driver<[HistorySectionModel]>
    }
    
    struct InputDetail {
        let backTrigger: Driver<Void>
        let updateSections: Driver<Void>
        let loadDay: Driver<Date>
        let addFaceTrigger: Driver<APIPlog>
        let deleteFaceTrigger: Driver<APIPlog>
        let displayHintTrigger: Driver<Void>
        let trackEventTrigger: Driver<(APIPlog, String)>
        let untrackEventTrigger: Driver<APIPlog>
    }
    
    struct OutputDetail {
        let availableDays: Driver<AvailableDays>
        let isLoading: Driver<Bool>
        let sections: Driver<[HistorySectionModel]>
        let camMap: Driver<[APICamMap]>
        let trackedEvents: Driver<[String: APITrackedEvent]>
    }
    
    func orderOf(row: Int, count: Int) -> HistoryCellOrder {
        return {
            switch row {
            case 0:
                return count == 1 ? .single : .first
            case count - 1:
                return .last
            default:
                return .regular
            }
        }()
    }

    private func analyticsEventType(from event: APIPlog.EventType) -> String {
        switch event {
        case .unanswered, .answered, .call:
            return "call"
        case .rfid:
            return "rfid_access"
        case .app, .passcode:
            return "door_opened"
        case .face:
            return "face_access"
        case .plate:
            return "motion"
        case .reserved, .unknown:
            return AnalyticsValue.unknown
        }
    }

    private func logEventDetailsOpened(_ event: APIPlog) {
        let eventType = analyticsEventType(from: event.event)
        let hasMedia = event.previewURL != nil || event.previewImage != nil

        AppAnalytics.log(
            AppAnalyticsEvent.eventDetailsOpened(
                eventType: eventType,
                source: "events_list",
                hasMedia: hasMedia
            )
        )

        if event.cameraId != nil {
            AppAnalytics.log(
                AppAnalyticsEvent.eventVideoOpened(
                    eventType: eventType,
                    source: "events_list"
                )
            )
        } else if hasMedia {
            AppAnalytics.log(
                AppAnalyticsEvent.eventImageOpened(
                    eventType: eventType,
                    source: "events_list"
                )
            )
        }
    }
}

extension HistoryViewModel {
    func loadTrackedEvents(for flatIds: [Int]) {
        guard apiWrapper.accessService.eventsTrackingEnabled else {
            trackedEvents.accept([:])
            return
        }

        guard !flatIds.isEmpty else {
            trackedEvents.accept([:])
            return
        }

        let requests = flatIds.map { flatId in
            apiWrapper
                .getTrackedEvents(flatId: flatId)
                .trackError(errorTracker)
                .asObservable()
                .catchAndReturn(nil)
        }

        Observable.zip(requests)
            .map { responses -> [String: APITrackedEvent] in
                responses
                    .flatMap { $0 ?? [] }
                    .reduce(into: [String: APITrackedEvent]()) { result, event in
                        result[event.key] = event
                    }
            }
            .bind(to: trackedEvents)
            .disposed(by: disposeBag)
    }
}
