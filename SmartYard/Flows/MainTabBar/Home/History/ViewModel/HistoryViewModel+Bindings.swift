// Created by Александр Попов. Copyright © 2026 Sesameware.

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import CoreLocation
import RxDataSources

extension HistoryViewModel {
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func bind() {
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

                    self.dataCache = self.dataCache.map { entry in
                        let newItems = entry.items.map { item -> APIPlog in
                            item.uuid == updatedEvent.uuid ? updatedEvent : item
                        }

                        return DayFlatItemsData(day: entry.day, items: newItems, flatId: entry.flatId)
                    }

                    self.updateAvailableDays.onNext(true)

                }
            )
            .disposed(by: disposeBag)
    }

    func bindEventUntracking(_ input: InputDetail) {
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
    }

    func bindEventTracking(_ input: InputDetail) {
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
    }
}
