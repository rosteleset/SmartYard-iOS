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
    
    /// идентификатор дома для какого смотрим логи
    private let houseId: String
    
    ///Адрес этого дома
    private let address: BehaviorSubject<String?>
    
    ///список доступных квартир по адресу на сервере
    public var flatIds: [Int] = []
    
    ///список номеров доступных квартир по адресу на сервере
    public var flatNumbers: [Int] = [] //список номеров доступных квартир по адресу на сервере
    
    ///список id квартир для отображения с учётом фильтра
    //public var flatIdsFilter: [Int] = []
    
    /// массив из квартир с массивом дат, доступных для каждой с учётом текущих фильтров
    private let availableDays = BehaviorRelay<AvailableDays>(value: [:])
    
    /// облегчённая версия availableDays - массив из доступных дат с учётом текущих фильтров
    private var uniqueDays: [Date] = []
    
    /// Очередь активных запросов на загрузку (FlatId, Date) - запросы по которым мы уже ожидаем данные и повторно их не запрашиваем
    private var loadingQueue: [(flatId: Int, day: Date)] = []
    
    /// сюда прилетают результаты запросов с API: один элемент - один день для одной квартиры
    private let logs = PublishSubject<DataSection>()
    
    /// все загруженные данные от API
    private let dataCache = BehaviorRelay<[DataSection]>(value: [])
    
    /// данные для отображения в виде готовых секций для dataSource с учётом текущих фильтров
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
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func transform(_ input: Input) -> Output {
        let errorTracker = ErrorTracker()
        let activityTracker = ActivityTracker()
        let availableDaysForFlat = PublishSubject<AvailableDays>()
        let updateSections = PublishSubject<Void>()
        let updateAvailableDays = PublishSubject<Void>()
        
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
                self.apptsFilter.value.forEach { flatId in
                    //проверяем, что для этой квартиры есть записи в этот день
                    guard let days = self.availableDays.value[flatId],
                          days.contains( where: { $0.day == day  })
                    //иначе переходим к следующей квартире.
                    else {
                        return
                    }
                    
                    lock.lock()
                    let isInQueue = self.loadingQueue.first { $0.flatId == flatId && $0.day == day }
                    let isInCache = self.dataCache.value.first { $0.flatId == flatId && $0.day == day }
                    
                    //если мы уже запрашиваем или имеем в кеше этот элемент, то не запрашиваем его повторно
                    guard isInQueue == nil, isInCache == nil else {
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
        
        input.apptsFilterString
            .map { [weak self] flatString -> [Int] in
                guard let self = self else {
                    return []
                }
                
                let flatInt: Int = Int(flatString) ?? 0
                if flatInt > 0 {
                    return [flatInt]
                } else {
                    return self.flatIds
                }
            }
            .drive(apptsFilter)
            .disposed(by: disposeBag)
        
        //при изменении фильтров обновляем список дней
        Observable.combineLatest(eventsFilter, apptsFilter)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
            .drive(updateAvailableDays)
            .disposed(by: disposeBag)
        
        //отсюда прилетает свежая порция событий журнала за день для квартиры от API
        logs.asDriverOnErrorJustComplete()
            .drive { [weak self] data in
                guard let self = self else {
                    return
                }
                
                //дополняем кэш полученной порцией данных
                self.dataCache.accept(self.dataCache.value + [data])
                
                self.loadingQueue.removeAll { $0.flatId == data.flatId && $0.day == data.day }
                
                //чтобы лишний раз не дёргать контроллер, обновляем данные, только когда вся очередь загрузки будет пустой.
                if self.loadingQueue.isEmpty {
                    updateSections.onNext(())
                }
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
                
                //собираем со всех квартир доступные даты, агрегируем
                self.uniqueDays = Array(data.values)
                    .flatMap { $0 }
                    .map { $0.day }
                    .duplicatesRemoved()
                    .sorted(by: >)
                
                //Если мы обладаем данными для всех квартир из фильтра, то обновляем секции для таблицы
                if data.count == self.apptsFilter.value.count {
                    updateSections.onNext(())
                }
            }
            .disposed(by: disposeBag)
            
        //выдаёт в sections готовые секции для dataModel в учётом всех фильтров
        updateSections
            //.debug()
            .asDriverOnErrorJustComplete()
            .debounce(.milliseconds(100))
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    
                    let result = self.uniqueDays
                        //делаем заготовку будущей секции из массива дат, вообще доступных на сервере
                        .map { sectionDay -> (day: Date, items: [APIPlog]) in
                        return (
                            day: sectionDay,
                            items: self.dataCache.value
                                //для каждой даты делаем выборку всех доступных данных в кэше,
                                //заодно сразу отфильтровываем данные по квартирам, которые не попадают в фильтр
                                .filter { $0.day == sectionDay && self.apptsFilter.value.contains($0.flatId) }
                                //отрезаем нам не нужные лишние поля даты и квартиры и объединяем массивы данных от разных квартир в один общий
                                .flatMap { $0.items }
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
                                    .filter {
                                        //если выбраны "все" события в фильтре, то не фильтруем совсем
                                        if self.eventsFilter.value == .all {
                                            return true
                                        }
                                        var eventType: EventsFilter
                                        //иначе: мапим тип события с фильтром
                                        switch $0.event {
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
                                        return eventType == self.eventsFilter.value
                                    }
                                    .enumerated()
                                    //поскольку RxDataSource определяет небходимость обновлять ячейки по изменению их содержимого,
                                    //то приходится в элементах хранить атрибут позиции внутри секции, чтобы TableView правильно перерисовывал
                                    //закругления и управлял отображением заголовка секции в каждой первой ячейке.
                                    .map {
                                        HistoryDataItem(
                                            identity: $0.element.uuid,
                                            order: self.orderOf(row: $0.offset, count: items.count),
                                            value: $0.element
                                        )
                                    }
                            )
                        }
                        //удаляем секции тех дней, для которых из-за фильтра по типу событий не оказалось ни одной записи
                        .filter { $0.items.isEmpty == false }
                        
                    self.sections.onNext(result)
                }
            )
            .disposed(by: disposeBag)
        
        updateAvailableDays
            .asDriverOnErrorJustComplete()
            .flatMap { [weak self] _ -> Driver<AvailableDays?> in
                guard let self = self else {
                    return .just(nil)
                }
                
                //сбрасываем данные от предыдущих запросов, но кэш не трогаем.
                self.uniqueDays = []
                self.availableDays.accept([:])
                
                let results = PublishSubject<AvailableDays?>()
                
                //запрашиваем список дней, имеющих логи для каждой квартиры, а результат каждого запроса отправляем,
                //как отдельный элемент в текущую последовательность
                self.apptsFilter.value.forEach { flatId in
                    self.apiWrapper.plogDays(flatId: flatId, events: self.eventsFilter.value)
                        .trackError(errorTracker)
                        .map { $0 == nil ?  nil : [flatId: $0!] } //поскольку ответ не содержит flatId, то мы сами пробрасываем flatId из запроса
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
        
        // мы знаем только id дома, а логи запрашиваются для id квартиры,
        //поэтому получаем список настроек чтобы понять по id дома идентификатор первой доступной квартиры в данном доме
        //на будущее надо заменить на запросы логов для каждой квартиры.
        apiWrapper.getSettingsAddresses()
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive { [weak self] args in
                guard let self = self else {
                    return
                }
                
                //получаем список идентификаторов квартир по выбранному адресу и преобразуем тип к Int
                self.flatIds = args.filtered ( { $0.houseId == self.houseId },  map: { (Int($0.flatId!) ?? -1) } )
                
                //получаем список номеров квартир по выбранному адресу и преобразуем тип к Int
                self.flatNumbers = args.filtered ( { $0.houseId == self.houseId },  map: { (Int($0.flatNumber!) ?? -1) } )
                
                //по умолчанию фильтр содержит все доступные квартиры
                self.apptsFilter.accept(self.flatIds)
                
                //изменение фильтра запустит запрос списков дат для квартир, поэтому больше ничего отсюда уже можно не дёргать
            }
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
        let apptsFilterString: Driver<String>
        
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
