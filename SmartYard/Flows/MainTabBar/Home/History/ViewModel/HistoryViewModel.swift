//
//  YardMapViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import CoreLocation
import RxDataSources

typealias FlatId = Int
typealias AvailableDays = [FlatId: PlogDaysResponseData] //[FlatId: [APIPlogDay]]

class HistoryViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<HomeRoute>
    private let houseId: String // идентификатор дома для какого смотрим логи
    private let address: BehaviorSubject<String?> //Адрес этого дома
    private var flatIds: [Int] = [] //список доступных квартир по адресу
    
    /// массив из квартир с массивом дат, доступных для каждой.
    private let availableDays = BehaviorRelay<AvailableDays>(value: [:])
    
    /// облегчённая версия availableDays - массив из доступных на сервере дат для всех квартир
    private var uniqueDays: [Date] = []
    
    /// сюда прилетают результаты запросов с API: один элемент - один день для одной квартиры
    private let logs = PublishSubject<DataSection>()
    
    /// Очередь активных запросов на загрузку (FlatId, Date) - запросы по которым мы ожидаем данные и повторно их не запрашиваем
    private var loadingQueue: [(flatId: Int, day: Date)] = []
    
    /// Очередь ожидающих запросов на загрузку (FlatId, Date) - запросы по которым мы пока не запрашивали данные
    private var waitingQueue: [(flatId: Int, day: Date)] = []
    
    /// все загруженные данные от API
    private let dataCache = BehaviorRelay<[DataSection]>(value: [])
    
    /// данные для отображения в виде готовых секций для dataSource
    private let sections = PublishSubject<[HistorySectionModel]>()
    
    /// датасорс для таблицы
    public var dataSource: RxTableViewSectionedAnimatedDataSource<HistorySectionModel>?
    
    ///фильтр по типам событий
    public var eventsFilter = BehaviorRelay<EventsFilter>(value: .all)
    
    ///фильтр по квартирам
    public var apptsFilter = BehaviorRelay<[Int]>(value: [])
    
    init(apiWrapper: APIWrapper, houseId: String, address: String, router: WeakRouter<HomeRoute>) {
        self.apiWrapper = apiWrapper
        self.houseId = houseId
        self.router = router
        self.address = BehaviorSubject<String?>(value: address)
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        let errorTracker = ErrorTracker()
        let activityTracker = ActivityTracker()
        let availableDaysForFlat = PublishSubject<AvailableDays>()
        let updateSections = PublishSubject<(EventsFilter, [FlatId])>()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        input.loadDay
            .distinctUntilChanged()
            .flatMap { [weak self] day -> Driver<DataSection?> in
                    
                guard let self = self else {
                    return .just(nil)
                }
                
                let lock = NSLock()
                
                let results = PublishSubject<DataSection?>()
                
                //запрашиваем логи за день для каждой квартиры и результат каждого запроса отправляем,
                //как отдельный элемент в текущую последовательность
                self.flatIds.forEach { flatId in
                    //проверяем, что для этой квартиры есть записи в этот день
                    guard let days = self.availableDays.value[flatId],
                          days.contains(where: { value -> Bool in
                            return value.day == day
                          })
                    //иначе переходим к следующей квартире.
                    else {
                        return
                    }
                    
                    lock.lock()
                    let isInQueue = self.loadingQueue.first { $0.flatId == flatId && $0.day == day }
                    
                    //если мы уже запрашиваем этот элемент, то не запрашиваем его повторно
                    if isInQueue != nil {
                        lock.unlock()
                        return
                    }
                    
                    self.loadingQueue.append((flatId: flatId, day: day))
                    lock.unlock()
                    
                    self.apiWrapper.plog(flatId: flatId, fromDate: day)
                    .trackError(errorTracker)
                    .map { $0 == nil ?  nil : (day: day, items: $0!, flatId: Int(flatId) ) }
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
        
        input.eventsFilter
            .drive(eventsFilter)
            .disposed(by: disposeBag)
        
        eventsFilter
            .asDriverOnErrorJustComplete()
            .drive { [weak self] eventsFilter in
                guard let self = self else {
                    return
                }
                
                updateSections.onNext((eventsFilter, self.apptsFilter.value))
            }
            .disposed(by: disposeBag)
        
        //отсюда прилетает свежая порция событий журнала за день для квартиры от API
        logs.asDriverOnErrorJustComplete()
            .drive { [weak self] data in
                guard let self = self else {
                    return
                }
                
                //дополняем кэш полученной порцией данных
                self.dataCache.accept(self.dataCache.value + [data])
                updateSections.onNext((self.eventsFilter.value, self.apptsFilter.value))
            }
            .disposed(by: disposeBag)

        availableDaysForFlat
            .asDriver(onErrorJustReturn: [:]) //отсюда прилетает список доступных в журнале дней для каждой квартиры
            .drive { [weak self] data in
                guard let self = self else {
                    return
                }
                
                //добавляем новую порцию данных, объединяя массивы данных для одинаковых flatId
                let newValue = self.availableDays.value.merging(data, uniquingKeysWith: +)
                
                self.availableDays.accept(newValue)
            }
            .disposed(by: disposeBag)
        
        //отсюда прилетает суммарный список всех доступных в журнале логов дат с количеством – по элементу на каждую квартиру
        availableDays
            .asDriver(onErrorJustReturn: [:])
            .drive { [weak self] data in
                guard let self = self else {
                    return
                }
                
                self.uniqueDays = Array(data.values)
                    .flatMap { $0 }
                    .map { $0.day }
                    .duplicatesRemoved()
            }
            .disposed(by: disposeBag)
            
        //выдаёт в sections готовые секции для dataModel в учётом всех фильтров
        updateSections.asDriverOnErrorJustComplete()
            .debounce(.milliseconds(1000))
            .drive { [weak self] (events, flats) in
                guard let self = self else {
                    return
                }
                
                //если фильтр пустой, то значит отображаем все квартиры, иначе заполняем фильтр квартирами согласно выбора пользователя.
                let flatIdsFilter = self.apptsFilter.value.isEmpty ? self.flatIds : self.apptsFilter.value
                
                let result = self.uniqueDays
                    //делаем заготовку будущей секции из массива дат, вообще доступных на сервере
                    .map { sectionDay -> (day: Date, items: [APIPlog]) in
                    return (
                        day: sectionDay,
                        items: self.dataCache.value
                            //для каждой даты делаем выборку всех доступных данных в кэше,
                            //заодно сразу отфильтровываем данные по квартирам, которые не попадают в фильтр
                            .filter { (day: Date, items: [APIPlog], flatId: Int) in
                                return day == sectionDay && flatIdsFilter.contains(flatId)
                            }
                            //отрезаем нам не нужные лишние поля даты и квартиры и объединяем массивы данных от разных квартир в один общий
                            .flatMap { (day: Date, items: [APIPlog], flatId: Int) -> [APIPlog] in
                                return items
                            }
                            //удаляем записи с одинаковым uuid, которые одновременно могли присутствовать в разных квартирах
                            .duplicatesRemoved()
                        )
                    }
                    //удаляеем даты в которых нет ни одной записи
                    .filter { !$0.items.isEmpty }
                    //превращаем получившийся массив в секции: одна дата – одна секция
                    .map { (day: Date, items: [APIPlog]) -> HistorySectionModel in
                        return HistorySectionModel(
                            identity: day,
                            itemsCount: items.count,
                            state: .loaded,
                            items: items
                                //сами элементы в секциях фильтруем в соответствии с фильтром отображаемых событий
                                .enumerated()
                                .map { HistoryDataItem(
                                    identity: $0.element.uuid,
                                    order: self.orderOf(row: $0.offset, count: items.count),
                                    value: $0.element
                                )}
                                .filter {
                                    //если выбраны "все" события в фильтре, то не фильтруем совсем
                                    if events == .all {
                                        return true
                                    }
                                    var eventType: EventsFilter
                                    //иначе: мапим тип события с фильтром
                                    switch $0.value.event {
                                    case .unanswered, .answered:
                                        eventType = .domophones
                                    case .rfid:
                                        eventType = .keys
                                    case .app:
                                        eventType = .application
                                    case .face:
                                        eventType = .faces
                                    case .passcode:
                                        eventType = .code
                                    case .call, .plate:
                                        eventType = .wickets
                                    case .unknown:
                                        eventType = .all
                                    }
                                    //и фильтруем, только те типы, которые совпадают с фильтром
                                    return eventType == events
                                }
                        )
                    }
                    //удаляем секции тех дней, для которых из-за фильтра по типу событий не оказалось ни одной записи
                    .filter { section -> Bool in
                        return !section.items.isEmpty
                    }

                self.sections.onNext(result)
            }
            .disposed(by: disposeBag)
        
        // мы знаем только id дома, а логи запрашиваются для id квартиры,
        //поэтому получаем список настроек чтобы понять по id дома идентификатор первой доступной квартиры в данном доме
        //на будущее надо заменить на запросы логов для каждой квартиры.
        apiWrapper.getSettingsAddresses()
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .flatMap { [weak self] args -> Driver<AvailableDays?> in
                guard let self = self else {
                    return .just(nil)
                }
                
                self.flatIds = args.filtered ( { $0.houseId == self.houseId },  map: { (Int($0.flatId!) ?? -1) } )
                //TODO: добавить запросы для всех квартир
                
                let results = PublishSubject<AvailableDays?>()
                
                //запрашиваем список дней, имеющих логи для каждой квартиры, а результат каждого запроса отправляем,
                //как отдельный элемент в текущую последовательность
                self.flatIds.forEach { flatId in
                    self.apiWrapper.plogDays(flatId: flatId)
                        .trackError(errorTracker)
                        .map { $0 == nil ?  nil : [flatId: $0!] } //поскольку ответ не содержит flatId, то мы сами пробрасываем flatId из запроса
                        .asDriver(onErrorJustReturn: nil)
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
        
        return Output(
            availableDays: availableDays.asDriver(onErrorJustReturn: [:]),
            address: address.asDriverOnErrorJustComplete(),
            isLoading: activityTracker.asDriver(),
            plog: logs.asDriverOnErrorJustComplete(),
            sections: sections
        )
    }
    
}

extension HistoryViewModel {
    
    struct Input {
        let itemSelected: Driver<Int>
        let backTrigger: Driver<Void>
        let loadDay: Driver<Date>
        let eventsFilter: Driver<EventsFilter>
    }
    
    struct Output {
        let availableDays: Driver<AvailableDays>
        let address: Driver<String?>
        let isLoading: Driver<Bool>
        let plog: Driver<DataSection>
        let sections: Observable<[HistorySectionModel]>
    }
    
    private func orderOf(row: Int, count: Int) -> HistoryCellOrder
    {
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
}
