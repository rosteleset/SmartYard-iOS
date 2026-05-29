//
//  YardMapViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import CoreLocation
import RxDataSources

typealias FlatId = Int
typealias AvailableDays = [FlatId: PlogDaysResponseData] // [FlatId: [APIPlogDay]]

// swiftlint:disable:next type_body_length
final class HistoryViewModel: BaseViewModel {

    private let apiWrapper: APIWrapper
    private let router: WeakRouter<HistoryRoute>

    private let errorTracker = ErrorTracker()
    private let activityTracker = ActivityTracker()
    private let availableDaysForFlat = PublishSubject<AvailableDays>()
    private let updateSections = PublishSubject<Void>()
    private let updateAvailableDays = PublishSubject<Bool>()

    /// идентификатор дома для какого смотрим логи
    private let houseId: String?
    private let flatId: Int?

    /// Адрес этого дома
    private let address: BehaviorSubject<String?>

    /// список доступных квартир по адресу на сервере
    var flatIds: [Int] = []

    /// список номеров доступных квартир по адресу на сервере
    var flatNumbers: [Int] = []

    /// признак того, надо ли отключать получение ответов из кеша сервера.
    private var forceRefresh = false

    /// массив из квартир с массивом дат, доступных для каждой с учётом текущих фильтров
    private var availableDays: AvailableDays = [:]

    /// массив из квартир с массивом дат, доступных для каждой с учётом текущих фильтров
    private let availableDaysSubject = BehaviorSubject<AvailableDays>(value: [:])

    /// облегчённая версия availableDays - массив из доступных дат с учётом текущих фильтров
    private var uniqueDays: [Date] = []

    /// Очередь активных запросов на загрузку (FlatId, Date)
    /// - запросы по которым мы уже ожидаем данные и повторно их не запрашиваем
    private var loadingQueue: [(flatId: Int, day: Date)] = []

    /// сюда прилетают результаты запросов с API: один элемент - один день для одной квартиры
    private let logs = PublishSubject<DayFlatItemsData>()

    /// все загруженные данные от API
    private var dataCache: [DayFlatItemsData] = []

    /// данные для отображения в виде готовых секций для dataSource с учётом текущих фильтров
    private let sections = BehaviorRelay<[HistorySectionModel]>(value: [])

    /// фильтр по типам событий
    private let eventsFilter = BehaviorRelay<EventsFilter>(value: .all)

    /// фильтр по квартирам
    private let apptsFilter = BehaviorRelay<[Int]>(value: [])

    /// таблица соответствия objectId <-> url flussonic
    private let camMap = BehaviorRelay<[APICamMap]>(value: [])

    /// таблица лиц по квартирам
    private var listFaces: [FlatId: GetPersonFacesResponseData] = [:]

    /// таблица отслеживаемых событий: "\(flatId)_\(eventType)_\(eventDetail)" -> watcher.
    private let trackedEvents = BehaviorRelay<[String: APITrackedEvent]>(value: [:])

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

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    private func bind() {
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

        // при изменении фильтров обновляем список дней
        Observable.combineLatest(self.eventsFilter, self.apptsFilter)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
            .map { self.forceRefresh }
            .drive(updateAvailableDays)
            .disposed(by: disposeBag)

        // отсюда прилетает свежая порция событий журнала за день для квартиры от API
        logs.asDriverOnErrorJustComplete()
            .drive { [weak self] data in
                guard let self else {return }

                // дополняем кэш полученной порцией данных
                if let index = self.dataCache.firstIndex(
                    where: { ($0.day == data.day) && ($0.flatId == data.flatId) }
                ) {
                    self.dataCache[index].items = data.items
                } else {
                    self.dataCache += [data]
                }

                self.loadingQueue.removeAll { $0.flatId == data.flatId && $0.day == data.day }

                // чтобы лишний раз не дёргать контроллер, обновляем данные,
                // только когда вся очередь загрузки будет пустой.
                if self.loadingQueue.isEmpty {
                    self.updateSections.onNext(())
                }
            }
            .disposed(by: disposeBag)

        availableDaysForFlat
            .asDriver(onErrorJustReturn: [:]) // отсюда прилетает список доступных в журнале дней для каждой квартиры
            .drive { [weak self] data in
                guard let self else { return }

                // добавляем новую порцию данных, объединяя массивы данных для одинаковых flatId
                self.availableDays.merge(data, uniquingKeysWith: +)
                self.availableDaysSubject.onNext(self.availableDays)
            }
            .disposed(by: disposeBag)

        // отсюда прилетает суммарный список всех доступных в журнале логов дат с количеством
        // – по элементу на каждую квартиру
        availableDaysSubject
            .asDriver(onErrorJustReturn: [:])
            .drive { [weak self] data in
                guard let self else { return }

                // Если мы обладаем данными для всех квартир из фильтра, то обновляем данные для таблицы
                if data.count == self.apptsFilter.value.count {
                    // собираем со всех квартир доступные даты, агрегируем
                    self.uniqueDays = Array(data.values)
                        .flatMap { $0 }
                        .map { $0.day }
                        .withoutDuplicates()
                        .sorted(by: >)

                    self.updateSections.onNext(())
                }
            }
            .disposed(by: disposeBag)

        // выдаёт в sections готовые секции для dataModel с учётом всех фильтров
        updateSections
            .asDriverOnErrorJustComplete()
            .debounce(.milliseconds(100))
            .drive(
                // swiftlint:disable:next closure_body_length
                onNext: { [weak self] _ in
                    guard let self else { return }

                    let result = self.uniqueDays
                    // делаем заготовку будущей секции из массива дат, вообще доступных на сервере
                        .map { sectionDay -> (day: Date, items: [APIPlog]) in
                            return (
                                day: sectionDay,
                                items: self.dataCache
                                // для каждой даты делаем выборку всех доступных данных в кэше,
                                // заодно сразу отфильтровываем данные по квартирам, которые не попадают в фильтр
                                    .filter { $0.day == sectionDay && self.apptsFilter.value.contains($0.flatId) }
                                // отрезаем нам не нужные лишние поля даты и квартиры
                                // и объединяем массивы данных от разных квартир в один общий
                                    .flatMap { $0.items }
                                // удаляем записи с одинаковым uuid, которые одновременно могли присутствовать
                                // в разных квартирах
                                    .withoutDuplicates()
                                // сортируем события внутри даты от самой ранней к более поздней
                                    .sorted(by: { $0.date > $1.date })
                            )
                        }
                    // удаляеем даты в которых нет ни одной записи
                        .filter { !$0.items.isEmpty }
                    // сами элементы в секциях фильтруем в соответствии с фильтром отображаемых событий
                    // swiftlint:disable:next closure_body_length
                        .map { (day: Date, items: [APIPlog]) -> (day: Date, items: [APIPlog]) in
                            let itemsFiltered = items.filter {
                                // если выбраны "все" события в фильтре, то не фильтруем совсем
                                if self.eventsFilter.value == .all {
                                    return true
                                }
                                var eventType: EventsFilter
                                // иначе: мапим тип события с фильтром
                                switch  $0.event {
                                case .unanswered, .answered: eventType = .domophones
                                case .rfid:                  eventType = .keys
                                case .app:                   eventType = .application
                                case .face:                  eventType = .faces
                                case .passcode:              eventType = .code
                                case .call, .plate:          eventType = .phoneCall
                                case .reserved, .unknown:    eventType = .all
                                }
                                // и фильтруем, только те типы, которые совпадают с фильтром
                                return eventType == self.eventsFilter.value
                            }
                            return (day: day, items: itemsFiltered)
                        }
                    // превращаем получившийся массив в секции: одна дата – одна секция
                        .map { (day: Date, items: [APIPlog]) -> HistorySectionModel in
                            return HistorySectionModel(
                                identity: day,
                                itemsCount: items.count,
                                state: .loaded,
                                items: items
                                    .enumerated()
                                // поскольку RxDataSource определяет небходимость обновлять ячейки по изменению их содержимого,
                                // то приходится в элементах хранить атрибут позиции внутри секции, чтобы TableView правильно перерисовывал
                                // закругления и управлял отображением заголовка секции в каждой первой ячейке.
                                    .map { // RxDataSource отслеживает изменения данных по identity, поэтому,
                                        // чтобы при изменении flags данные обновлялись, пришлось замиксовать uuid и flags в идентификатор
                                        HistoryDataItem(
                                            identity: $0.element.uuid + String(($0.element.detailX?.flags ?? []).joined(separator: ":")).md5,
                                            order: self.orderOf(row: $0.offset, count: items.count),
                                            value: $0.element
                                        )
                                    }
                            )
                        }
                    // удаляем секции тех дней, для которых из-за фильтра по типу событий не оказалось ни одной записи
                        .filter { $0.items.isEmpty == false }

                    self.sections.accept(result)
                }
            )
            .disposed(by: disposeBag)

        updateAvailableDays // аргумент - forceRefresh
            .asDriverOnErrorJustComplete()
            .flatMap { [weak self] forceRefresh -> Driver<AvailableDays?> in
                guard let self else { return .just(nil) }

                // сбрасываем данные от предыдущих запросов, но кэш не трогаем.
                self.uniqueDays = []
                self.availableDays = [:]
                self.forceRefresh = forceRefresh

                let results = PublishSubject<AvailableDays?>()

                // запрашиваем список дней, имеющих логи для каждой квартиры, а результат каждого запроса отправляем,
                // как отдельный элемент в текущую последовательность
                self.apptsFilter.value.forEach { flatId in
                    self.apiWrapper.plogDays(
                        flatId: flatId,
                        events: self.eventsFilter.value,
                        forceRefresh: forceRefresh
                    )
                    .trackError(self.errorTracker)
                    .trackActivity(self.activityTracker)
                    // поскольку ответ не содержит flatId, то мы сами пробрасываем flatId из запроса
                    .map { $0 == nil ? nil : [flatId: $0!] }
                    .asDriver(onErrorJustReturn: [flatId: []])
                    .drive { result in
                        results.onNext(result)
                    }
                    .disposed(by: self.disposeBag)
                }

                return results.asDriver(onErrorJustReturn: nil)
            }
            .trackError(errorTracker)
            .ignoreNil()
            .bind(to: availableDaysForFlat)
            .disposed(by: disposeBag)

        // обновляем список лиц по тому же самому событию
        updateAvailableDays // аргумент - forceRefresh
            .asDriverOnErrorJustComplete()
            .flatMap { [weak self] forceRefresh -> Driver<[FlatId: GetPersonFacesResponseData]?> in
                guard let self else { return .just(nil) }

                self.listFaces = [:]
                let results = PublishSubject<[FlatId: GetPersonFacesResponseData]?>()

                // запрашиваем список дней, имеющих логи для каждой квартиры, а результат каждого запроса отправляем,
                // как отдельный элемент в текущую последовательность
                self.apptsFilter.value.forEach { flatId in
                    self.apiWrapper.getPersonFaces(flatId: flatId, forceRefresh: forceRefresh)
                        .trackError(self.errorTracker)
                    // поскольку ответ не содержит flatId, то мы сами пробрасываем flatId из запроса
                        .map { $0 == nil ? nil : [flatId: $0!] }
                        .asDriver(onErrorJustReturn: [flatId: []])
                        .drive { result in
                            results.onNext(result)
                        }
                        .disposed(by: self.disposeBag)
                }

                return results.asDriver(onErrorJustReturn: nil)
            }
            .trackError(errorTracker)
            .ignoreNil()
            .asDriver(onErrorJustReturn: [:])
            .drive(
                onNext: { [weak self] result in
                    guard let self else { return }

                    self.listFaces.merge(result) { _, new in new }
                }
            )
            .disposed(by: disposeBag)

        // мы знаем только id дома, а логи запрашиваются для id квартиры,
        // поэтому получаем список настроек чтобы понять по id дома идентификатор первой доступной квартиры в данном доме
        // на будущее надо заменить на запросы логов для каждой квартиры.
        let getSettingsAddresses = apiWrapper.getSettingsAddresses()
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()

        let getCamMap = apiWrapper.getCamMap()
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()

        if self.houseId == nil,
           let flatId = self.flatId {
            getCamMap
                .drive { [weak self] camMap in
                    guard let self else { return }

                    self.camMap.accept(camMap)

                    self.flatIds = [flatId]
                    self.flatNumbers = [0]
                    self.apptsFilter.accept(self.flatIds)
                    self.loadTrackedEvents(for: self.flatIds)
                    // изменение фильтра запустит запрос списков дат для квартир, поэтому больше ничего отсюда уже можно не дёргать
                }
                .disposed(by: disposeBag)
        } else {
            Driver.zip(getSettingsAddresses, getCamMap)
                .drive { [weak self] args, camMap in
                    guard let self else { return }

                    self.camMap.accept(camMap)

                    let filtered = args.filter { $0.houseId == self.houseId && $0.hasPlog }

                    // получаем список идентификаторов квартир по выбранному адресу и преобразуем тип к Int
                    self.flatIds = filtered
                        .compactMap { $0.flatId }
                        .compactMap { Int($0) }
                        .withoutDuplicates()

                    // получаем список номеров квартир по выбранному адресу и преобразуем тип к Int
                    self.flatNumbers = filtered
                        .compactMap { $0.flatNumber }
                        .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                        .withoutDuplicates()

                    // по умолчанию фильтр содержит все доступные квартиры
                    self.apptsFilter.accept(self.flatIds)
                    self.loadTrackedEvents(for: self.flatIds)

                    // изменение фильтра запустит запрос списков дат для квартир, поэтому больше ничего отсюда уже можно не дёргать
                }
                .disposed(by: disposeBag)
        }

        // если события изменились, то обновляем данные (dataCache не обнуляется при этом, а вот список лиц при этом обновится с сервера)
        NotificationCenter.default.rx.notification(.updateEvent)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] notification in
                    guard let self = self,
                          let updatedEvent = notification.object as? APIPlog else {
                        return
                    }

                    self.dataCache = self.dataCache.map { (day: Date, items: [APIPlog], flatId: Int) in
                        let newItems = items.map { item -> APIPlog in
                            item.uuid == updatedEvent.uuid ? updatedEvent : item
                        }

                        return (day, newItems, flatId)
                    }

                    self.updateAvailableDays.onNext(true)

                }
            )
            .disposed(by: disposeBag)
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
                            return (
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
                            return (
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

        input.trackEventTrigger
            .flatMapLatest { [weak self] event, comments -> Driver<APITrackedEvent?> in
                guard let self,
                      let flatId = event.flatId else {
                    return .empty()
                }

                let eventDetail = ParanoidEventTracking.eventDetail(from: event)

                return self.apiWrapper
                    .trackEvent(
                        flatId: flatId,
                        eventType: event.event.rawValue,
                        eventDetail: eventDetail,
                        comments: comments
                    )
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .map { response -> APITrackedEvent? in
                        guard let watcherId = response?.watcherId else { return nil }
                        return APITrackedEvent(
                            watcherId: watcherId,
                            flatId: flatId,
                            eventType: event.event.rawValue,
                            eventDetail: eventDetail,
                            comments: comments
                        )
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] trackedEvent in
                    guard let self else { return }

                    var events = trackedEvents.value
                    events[trackedEvent.key] = trackedEvent
                    trackedEvents.accept(events)
                }
            )
            .disposed(by: disposeBag)

        input.untrackEventTrigger
            .flatMapLatest { [weak self] event -> Driver<String?> in
                guard let self,
                      let key = ParanoidEventTracking.key(for: event),
                      let trackedEvent = trackedEvents.value[key] else {
                    return .empty()
                }

                return self.apiWrapper
                    .untrackEvent(watcherId: trackedEvent.watcherId)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .map { _ in key }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] key in
                    guard let self else { return }

                    var events = trackedEvents.value
                    events.removeValue(forKey: key)
                    trackedEvents.accept(events)
                }
            )
            .disposed(by: disposeBag)

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
    
    private func orderOf(row: Int, count: Int) -> HistoryCellOrder {
        return {
            switch row {
            case 0:
                return count == 1 ? .single : .first
            case count - 1 :
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

private extension HistoryViewModel {
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
