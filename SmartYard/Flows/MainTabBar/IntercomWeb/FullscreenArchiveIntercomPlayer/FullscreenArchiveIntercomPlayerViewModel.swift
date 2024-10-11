//
//  FullscreenArchiveIntercomPlayerViewModel.swift
//  SmartYard
//
//  Created by devcentra on 04.10.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length type_body_length large_tuple

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import RxDataSources

typealias EventsDays = [Date: PlogResponseData] // [Date: [APIPlog]]
typealias EventsDaysLoaded = [Date: Bool] // [Date: [APIPlog]]

class FullscreenArchiveIntercomPlayerViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<IntercomWebRoute>
    private let camId: Int

    private let cameras = PublishSubject<[CameraExtendedObject]>()
    
    var doors = [Int: DoorExtendedObject]()
    private let areDoorGrantAccessed = BehaviorRelay<[Int: Bool]>(value: [:])
    private let rangesForCamera = BehaviorSubject<[APIArchiveRange]?>(value: nil)
    private let selectedCamera = BehaviorSubject<CameraExtendedObject?>(value: nil)
    private let selectedCameraStatus = BehaviorSubject<Bool?>(value: nil)
    private let selectedStartEnd = BehaviorSubject<(Date, Date)?>(value: nil)
    private let clipSize = BehaviorSubject<String?>(value: nil)
    private let dateArchiveUpper = BehaviorSubject<Date?>(value: nil)
    private let dateArchiveParent = BehaviorSubject<Date?>(value: nil)
    private let lowerUpperDates = BehaviorSubject<(Date?, Date?)>(value: (nil, nil))
    private let areVideoMutted = BehaviorSubject<Bool>(value: true)

    private let activityTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()
    private var rangesDisposeBag = DisposeBag()
    private var eventsDisposeBag = DisposeBag()
    private let rangesLoadingTracker = ActivityTracker()

    let activityEventTracker = BehaviorSubject(value: false)
    private let availableDaysForFlat = PublishSubject<AvailableDays>()
    private let updateAvailableDays = PublishSubject<Bool>()
    
    /// признак того, надо ли отключать получение ответов из кеша сервера.
    private var forceRefresh = false
    /// массив из квартир с массивом дат, доступных для каждой с учётом текущих фильтров
    private var availableDays: EventsDays = [:]
    private var eventLoadedDays: EventsDaysLoaded = [:]
    /// массив из квартир с массивом дат, доступных для каждой с учётом текущих фильтров
    private let availableDaysSubject = BehaviorSubject<EventsDays>(value: [:])
    /// облегчённая версия availableDays - массив из доступных дат с учётом текущих фильтров
    private var uniqueDays: [Date] = []
    /// Очередь активных запросов на загрузку (FlatId, Date)
    /// - запросы по которым мы уже ожидаем данные и повторно их не запрашиваем
    private var loadingQueue: [(flatId: Int, day: Date)] = []
    /// сюда прилетают результаты запросов с API: один элемент - один день для одной квартиры
    private let logs = PublishSubject<DayFlatItemsData>()
    /// фильтр по квартирам
    private let flatsFilter = BehaviorRelay<[Int]>(value: [])
    private let daysFilter = BehaviorRelay<[Date]>(value: [])

    private var flatIds: [Int] = []

    init(
        apiWrapper: APIWrapper,
        camId: Int,
        router: WeakRouter<IntercomWebRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.camId = camId
        self.router = router
        
        super.init()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)

    }

    func clearDoorAccess() {
        areDoorGrantAccessed.accept([:])
    }
    
    func updateDoorButton(
        identify: Int,
        door: DoorExtendedObject
    ) {
        doors[identify] = door
        
        var value = areDoorGrantAccessed.value
        value[identify] = true
        areDoorGrantAccessed.accept(value)
    }
    
    func transformClip(_ input: InputClip) -> OutputClip {
        
        input.backTrigger
            .withLatestFrom(selectedStartEnd.asDriverOnErrorJustComplete())
            .drive(
                onNext: { [weak self] startenddate in
                    if let startenddate = startenddate {
                        let (fromdate, _) = startenddate
                        self?.dateArchiveParent.onNext(fromdate)
                    }
                    self?.router.trigger(.closeArchiveDownload)
                }
            )
            .disposed(by: disposeBag)
        
        input.startEndSelectedTrigger
            .drive(
                onNext: { [weak self] in
                    self?.selectedStartEnd.onNext(($0))
                    
                    let startDay = Calendar.novokuznetskCalendar.startOfDay(for: $0.0)
                    let isInEvents = self?.eventLoadedDays.first { $0.key == startDay }
                    
                    guard isInEvents == nil else {
                        return
                    }
                    
                    self?.updateEvents(startDay)
                }
            )
            .disposed(by: disposeBag)
        
        input.getSizeTrigger
            .withLatestFrom(selectedCamera.asDriverOnErrorJustComplete()) { ($0, $1) }
            .withLatestFrom(selectedStartEnd.asDriverOnErrorJustComplete()) { ($0, $1) }
            .flatMap { args -> Driver<(camId: Int, from: String, to: String)> in
                let (isGetAndCamera, startenddates) = args
                let (isget, camera) = isGetAndCamera
                
                guard isget, let uArgs = startenddates, let camera = camera else {
                    return .empty()
                }

                let (start, end) = uArgs

                guard end > start else {
                    return .empty()
                }

                let formatter = DateFormatter()

                formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

                return .just((camId: camera.id, from: formatter.string(from: start), to: formatter.string(from: end)))
            }
            .flatMapLatest { [weak self] range -> Driver<String?> in
                guard let self = self else {
                    return .empty()
                }

                return self.apiWrapper
                    .recSize(id: range.camId, from: range.from, to: range.to)
                    .trackError(self.errorTracker)
                    .trackActivity(self.activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] responseData in
                    guard let self = self else {
                        return
                    }
                    self.clipSize.onNext(responseData)
                }
            )
            .disposed(by: disposeBag)

        input.downloadTrigger
            .withLatestFrom(selectedCamera.asDriver(onErrorJustReturn: nil))
            .withLatestFrom(selectedStartEnd.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMap { args -> Driver<(camId: Int, from: String, to: String)> in
                let (camera, startenddates) = args
                
                guard let uArgs = startenddates, let camera = camera else {
                    return .empty()
                }
                
                let (start, end) = uArgs
                
                guard end > start else {
                    return .empty()
                }
                
                let formatter = DateFormatter()
                
                // MARK: А тут сервак жрет строки не в GMT, а в MSK
                
                formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                return .just((camId: camera.id, from: formatter.string(from: start), to: formatter.string(from: end)))
            }
            .flatMapLatest { [weak self] range -> Driver<Int?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .recPrepare(id: range.camId, from: range.from, to: range.to)
                    .trackError(self.errorTracker)
                    .trackActivity(self.activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .flatMapLatest { [weak self] fragmentId -> Driver<RecDownloadResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .recDownload(id: fragmentId)
                    .trackError(self.errorTracker)
                    .trackActivity(self.activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] responseData in
                    // Если нет урла - показываем "видео готовится"
                    guard let stringUrl = responseData.url else {
                        let msg = """
                        Как только процесс закончится, вам придет сообщение в чат.
                        В зависимости от длины видео процесс загрузки может занять от нескольких минут до нескольких часов.
                        """
                        
                        let okAction = UIAlertAction(title: "Спасибо", style: .default, handler: nil)
                        
                        self?.router.trigger(
                            .dialog(
                                title: "Видео готовится",
                                message: msg,
                                actions: [okAction]
                            )
                        )
                        
                        return
                    }
                    
                    guard let encodedString = stringUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                        let url = URL(string: encodedString) else {
                            // Если есть ссылка, но она кривая - копируем урл в пастборд и показываем алерт
                            UIPasteboard.general.string = stringUrl
                            
                            self?.router.trigger(
                                .alert(
                                    title: "Ссылка на видео скопирована в буфер обмена",
                                    message: nil
                                )
                            )
                            
                            return
                    }
                    
                    // Если смог получить нормальный URL - показываем share
                    self?.router.trigger(.share(items: [url]))
                }
            )
            .disposed(by: disposeBag)
        
        return OutputClip(
            lowerUpperDates: lowerUpperDates.asDriver(onErrorJustReturn: (nil, nil)),
            selectedDate: dateArchiveUpper.asDriver(onErrorJustReturn: nil),
            selectedCamera: selectedCamera.asDriver(onErrorJustReturn: nil),
            events: availableDaysSubject.asDriver(onErrorJustReturn: [:]),
            clipsize: clipSize.asDriver(onErrorJustReturn: nil)
        )
    }
    
    func transformLandscape(_ input: InputLandscape) -> OutputLandscape {
        
        input.buttons.enumerated().forEach { offset, button in
            button.rx.tap
                .asDriver()
                .drive(
                    onNext: { [weak self] in
                        guard let self = self, let door = self.doors[offset] as? DoorExtendedObject else {
                            return
                        }
                        var grantedDoors = self.areDoorGrantAccessed.value
                        guard let buttonActive = grantedDoors[offset], buttonActive else {
                            return
                        }

                        self.apiWrapper
                            .openDoor(domophoneId: door.domophoneId, doorId: door.doorId, blockReason: nil)
                            .trackActivity(self.activityTracker)
                            .trackError(self.errorTracker)
                            .asDriver(onErrorJustReturn: nil)
                            .ignoreNil()
                            .drive(
                                onNext: { [weak self] _ in
                                    grantedDoors[offset] = false
                                    self?.areDoorGrantAccessed.accept(grantedDoors)
                                    button.tintColor = UIColor.SmartYard.darkGreen
                                    button.layerBorderColor = UIColor.SmartYard.darkGreen
                                    self?.closeDoorAccessAfterTimeout(button, identity: offset)
                                }
                            )
                    }
                )
                .disposed(by: disposeBag)
        }

        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.closeFullscreenArchive)
                }
            )
            .disposed(by: disposeBag)
        
        input.muteTrigger
            .withLatestFrom(areVideoMutted.asDriver(onErrorJustReturn: true))
            .drive(
                onNext: { [weak self] isVideoMutted in
                    self?.areVideoMutted.onNext(!isVideoMutted)
                }
            )
            .disposed(by: disposeBag)
        
        input.lowerUpperSelectedTrigger
            .drive(
                onNext: { [weak self] in
                    self?.lowerUpperDates.onNext(($0))
                }
            )
            .disposed(by: disposeBag)
        
        input.dateArchiveTrigger
            .debounce(.microseconds(25))
            .distinctUntilChanged()
            .drive(
                onNext: { [weak self] date in
                    guard [.landscapeLeft, .landscapeRight].contains(UIApplication.shared.statusBarOrientation) else {
                        return
                    }
                    self?.dateArchiveUpper.onNext(date)
                    
                    let startDay = Calendar.novokuznetskCalendar.startOfDay(for: date ?? Date())
                    let isInEvents = self?.eventLoadedDays.first { $0.key == startDay }
                    
                    guard isInEvents == nil else {
                        return
                    }
                    
                    self?.updateEvents(startDay)
                }
            )
            .disposed(by: disposeBag)
        
        input.updateRangesTrigger
            .drive(
                onNext: { [weak self] camera in
                    guard let self = self, let camera = camera else {
                        return
                    }
                    self.updateAvailableDates(camera: camera)
                }
            )
            .disposed(by: disposeBag)
        
        return OutputLandscape(
            selectedDate: dateArchiveUpper.asDriver(onErrorJustReturn: nil),
            lowerUpperDates: lowerUpperDates.asDriver(onErrorJustReturn: (nil, nil)),
            selectedCamera: selectedCamera.asDriver(onErrorJustReturn: nil),
            rangesForCurrentCamera: rangesForCamera.asDriver(onErrorJustReturn: nil),
            events: availableDaysSubject.asDriver(onErrorJustReturn: [:]),
            isVideoMutted: areVideoMutted.asDriver(onErrorJustReturn: true),
            selectedCameraStatus: selectedCameraStatus.asDriver(onErrorJustReturn: nil)
        )
    }
    
    func updateEvents(_ day: Date){
        
        let lock = NSLock()

        flatsFilter.value.forEach { flatId in

            /// Здесь добавляем очередь запросов, пишем данные в кэш, когда очередь выполнится, обновляем события
            lock.lock()
            let isInQueue = loadingQueue.first { $0.flatId == flatId && $0.day == day }

            // если мы уже запрашиваем или имеем в кеше этот элемент, то не запрашиваем его повторно
            guard isInQueue == nil else {
                lock.unlock()
                return
            }
            self.activityEventTracker.onNext(true)

            loadingQueue.append((flatId: flatId, day: day))
            lock.unlock()

            apiWrapper.plog(flatId: flatId, fromDate: day, forceRefresh: false)
                .trackError(errorTracker)
                .map { $0 == nil ? nil : (day: day, items: $0!, flatId: Int(flatId)) }
                .asDriver(onErrorJustReturn: nil)
                .ignoreNil()
                .drive { result in
                    self.logs.onNext(result)
                }
                .disposed(by: disposeBag)
        }
    }
    
    func transform(_ input: Input) -> Output {
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.closeFullscreenArchive)
                }
            )
            .disposed(by: disposeBag)
        
        input.muteTrigger
            .withLatestFrom(areVideoMutted.asDriver(onErrorJustReturn: true))
            .drive(
                onNext: { [weak self] isVideoMutted in
                    self?.areVideoMutted.onNext(!isVideoMutted)
                }
            )
            .disposed(by: disposeBag)
        
        input.imageBackTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.closeFullscreenArchive)
                }
            )
            .disposed(by: disposeBag)
        
        input.lowerUpperSelectedTrigger
            .drive(
                onNext: { [weak self] in
                    self?.lowerUpperDates.onNext(($0))
                }
            )
            .disposed(by: disposeBag)
        
        input.shareTrigger
            .withLatestFrom(selectedCamera.asDriverOnErrorJustComplete())
            .withLatestFrom(lowerUpperDates.asDriverOnErrorJustComplete()) { ($0, $1) }
            .flatMap { args -> Driver<(upper: Date, lower: Date, camera: CameraExtendedObject)> in
                let (camera, lowerupper) = args
                let (lowerDate, upperDate) = lowerupper
                
                guard let lower = lowerDate, let upper = upperDate, let camera = camera else {
                    return .empty()
                }

                return .just((upper: upper, lower: lower, camera: camera))
            }
            .drive(
                onNext: { [weak self] upper, lower, camera in
                    guard let self = self else {
                        return
                    }
                    self.router.trigger(.archivedownload(vm: self))
                }
            )
            .disposed(by: disposeBag)
        
        input.dateArchiveTrigger
            .debounce(.microseconds(25))
            .distinctUntilChanged()
            .drive(
                onNext: { [weak self] date in
                    guard UIApplication.shared.statusBarOrientation == .portrait else {
                        return
                    }
                    self?.dateArchiveUpper.onNext(date)

                    let startDay = Calendar.novokuznetskCalendar.startOfDay(for: date ?? Date())
                    let isInEvents = self?.eventLoadedDays.first { $0.key == startDay }
                    
                    guard isInEvents == nil else {
                        return
                    }
                    
                    self?.updateEvents(startDay)
                }
            )
            .disposed(by: disposeBag)
        
        input.selectedCameraTrigger
            .drive(
                onNext: { [weak self] in
                    self?.selectedCamera.onNext($0)
                }
            )
            .disposed(by: disposeBag)

        input.updateRangesTrigger
            .drive(
                onNext: { [weak self] camera in
                    guard let self = self, let camera = camera else {
                        return
                    }
                    self.updateAvailableDates(camera: camera)
                }
            )
            .disposed(by: disposeBag)
        
        input.buttons.enumerated().forEach { offset, button in
            button.rx.tap
                .asDriver()
                .drive(
                    onNext: { [weak self] in
                        guard let self = self, let door = self.doors[offset] as? DoorExtendedObject else {
                            return
                        }
                        var grantedDoors = self.areDoorGrantAccessed.value
                        guard let buttonActive = grantedDoors[offset], buttonActive else {
                            return
                        }

                        self.apiWrapper
                            .openDoor(domophoneId: door.domophoneId, doorId: door.doorId, blockReason: nil)
                            .trackActivity(self.activityTracker)
                            .trackError(self.errorTracker)
                            .asDriver(onErrorJustReturn: nil)
                            .ignoreNil()
                            .drive(
                                onNext: { [weak self] _ in
                                    grantedDoors[offset] = false
                                    self?.areDoorGrantAccessed.accept(grantedDoors)
                                    button.tintColor = UIColor.SmartYard.darkGreen
                                    button.layerBorderColor = UIColor.SmartYard.darkGreen
                                    self?.closeDoorAccessAfterTimeout(button, identity: offset)
                                }
                            )
                    }
                )
                .disposed(by: disposeBag)
        }

        self.apiWrapper.getAllCCTV(houseId: nil)
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .map { response in
                response.enumerated().map { offset, element in
                    let camera = CameraExtendedObject(
                        id: element.id,
                        position: element.coordinate,
                        cameraNumber: offset + 1,
                        name: element.name,
                        video: element.video,
                        token: element.token,
                        doors: element.doors.enumerated().map { _, delement in
                                DoorExtendedObject(
                                    domophoneId: delement.domophoneId,
                                    doorId: delement.doorId,
                                    entrance: delement.entrance ?? "",
                                    type: delement.type.iconImageName,
                                    name: delement.name,
                                    blocked: delement.blocked ?? "",
                                    dst: delement.dst ?? ""
                                )
                        },
                        flatIds: element.flatIds,
                        type: nil,
                        status: nil
                    )
                    if element.id == self.camId {
                        self.selectedCamera.onNext(camera)
                    }
                    return camera
                }
            }
            .drive(
                onNext: { [weak self] in
                    self?.cameras.onNext($0)
                }
            )
            .disposed(by: disposeBag)

        selectedCamera
            .asDriver(onErrorJustReturn: nil)
            .do(
                onNext: { [weak self] _ in
                    self?.rangesForCamera.onNext(nil)
                    self?.flatIds = []
                    self?.flatsFilter.accept([])
                    self?.daysFilter.accept([])
                    self?.availableDays = [:]
                    self?.eventLoadedDays = [:]
                    self?.availableDaysSubject.onNext([:])
                    self?.loadingQueue = []
                    self?.areVideoMutted.onNext(true)
                    self?.selectedCameraStatus.onNext(nil)
                }
            )
            .ignoreNil()
            .flatMapLatest { [weak self] camera -> Driver<(CameraExtendedObject, AllCCTVResponseData)?> in
                guard let self = self else {
                    return .empty()
                }
                return self.apiWrapper.getCamCCTV(camId: camera.id)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .map {
                        guard let response = $0 else {
                            return nil
                        }
                        
                        return (camera, response)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .drive(
                onNext: { [weak self] args in
                    guard let self = self, let (camera, response) = args else {
                        return
                    }
                    if let element = response.first(where: {$0.id == camera.id}),
                       let status = element.status {
                        self.selectedCameraStatus.onNext(status)
                    }
                    print("CAMERA BY ID", camera)
                    self.flatIds = camera.flatIds
                        .compactMap { Int($0!) }
                        .withoutDuplicates()
                    self.flatsFilter.accept(self.flatIds)
                    self.updateAvailableDates(camera: camera)
                }
            )
            .disposed(by: disposeBag)
        
        logs.asDriverOnErrorJustComplete()
            .drive { [weak self] data in
                guard let self = self else {
                    return
                }
                
                if (self.loadingQueue.first { $0.flatId == data.flatId && $0.day == data.day } != nil) {
                    self.eventLoadedDays.merge([data.day: true]) { (current, _) in current}
                    if !data.items.isEmpty {
                        let events: EventsDays = [data.day: data.items]
                        self.availableDays.merge(events, uniquingKeysWith: +)
                    }
                }
                
                self.loadingQueue.removeAll { $0.flatId == data.flatId && $0.day == data.day }

                // чтобы лишний раз не дёргать контроллер, обновляем данные,
                // только когда вся очередь загрузки будет пустой.
                if self.loadingQueue.isEmpty {
                    self.availableDaysSubject.onNext(self.availableDays)
                    self.activityEventTracker.onNext(false)
                }
            }
            .disposed(by: disposeBag)

        rangesForCamera
            .asDriver(onErrorJustReturn: nil)
            .drive(
                onNext: { [weak self] ranges in
                    guard let self = self, let ranges = ranges, !ranges.isEmpty else {
                        return
                    }
                    let calendar = Calendar.novokuznetskCalendar
                    let startDay = ranges.compactMap { $0.startDate }.min()!
                    let endDay = ranges.compactMap { $0.endDate }.max()!
                    let preStartDay = calendar.date(byAdding: .day, value: -1, to: startDay)
                    
                    self.uniqueDays = []
                    self.availableDays = [:]
                    self.eventLoadedDays = [:]
                    self.loadingQueue = []
                    
                    let components = DateComponents(hour: 0, minute: 0, second: 0)
                    let dateRange = Calendar.current.enumerateDates(startingAfter: preStartDay!, matching: components, matchingPolicy: .nextTime) { (date, strict, stop) in
                        if let date = date {
                            if date <= endDay {
                                self.uniqueDays.append(date)
                            } else {
                                stop = true
                            }
                        }
                    }
                    self.daysFilter.accept(self.uniqueDays)
                    self.updateEvents(calendar.startOfDay(for: endDay))
                }
            )
            .disposed(by: disposeBag)

        return Output(
            isLoading: activityTracker.asDriver(),
            isVideoMutted: areVideoMutted.asDriver(onErrorJustReturn: true),
            cameras: cameras.asDriver(onErrorJustReturn: []),
            selectedCamera: selectedCamera.asDriver(onErrorJustReturn: nil),
            rangesForCurrentCamera: rangesForCamera.asDriver(onErrorJustReturn: nil),
            events: availableDaysSubject.asDriver(onErrorJustReturn: [:]),
            toDate: dateArchiveParent.asDriver(onErrorJustReturn: nil),
            selectedDate: dateArchiveUpper.asDriver(onErrorJustReturn: nil),
            isEventLoading: activityEventTracker.asDriver(onErrorJustReturn: false),
            selectedCameraStatus: selectedCameraStatus.asDriver(onErrorJustReturn: nil)
        )
    }

    private func updateAvailableDates(camera: CameraExtendedObject) {
        rangesDisposeBag = DisposeBag()
        
        DispatchQueue.main.async {
            self.apiWrapper
                .getArchiveRanges(cameraUrl: camera.video, from: 1525186456, token: camera.token)
                .trackActivity(self.rangesLoadingTracker)
                .trackError(self.errorTracker)
                .asDriver(onErrorJustReturn: nil)
                .ignoreNil()
                .drive(
                    onNext: { [weak self] ranges in
                        self?.rangesForCamera.onNext(ranges)
                    }
                )
                .disposed(by: self.rangesDisposeBag)
        }
    }
    
}

extension FullscreenArchiveIntercomPlayerViewModel {
    private func closeDoorAccessAfterTimeout(_ button: UIButton, identity: Int) {
        Timer.scheduledTimer(
            withTimeInterval: 5,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else {
                return
            }
            
            button.tintColor = UIColor.SmartYard.blue
            button.layerBorderColor = UIColor.SmartYard.blue
            var grantedDoors = self.areDoorGrantAccessed.value
            grantedDoors[identity] = true
            self.areDoorGrantAccessed.accept(grantedDoors)
        }
    }

}

extension FullscreenArchiveIntercomPlayerViewModel {
    
    struct Input {
        let selectedCameraTrigger: Driver<CameraExtendedObject>
        let updateRangesTrigger: Driver<CameraExtendedObject?>
        let dateArchiveTrigger: Driver<Date>
        let lowerUpperSelectedTrigger: Driver<(Date?, Date?)>
        let buttons: [UIButton]
        let backTrigger: Driver<Void>
        let imageBackTrigger: Driver<Void>
        let shareTrigger: Driver<Void>
        let muteTrigger: Driver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let isVideoMutted: Driver<Bool>
        let cameras: Driver<[CameraExtendedObject]>
        let selectedCamera: Driver<CameraExtendedObject?>
        let rangesForCurrentCamera: Driver<[APIArchiveRange]?>
        let events: Driver<EventsDays>
        let toDate: Driver<Date?>
        let selectedDate: Driver<Date?>
        let isEventLoading: Driver<Bool>
        let selectedCameraStatus: Driver<Bool?>
    }
    
    struct InputLandscape {
        let updateRangesTrigger: Driver<CameraExtendedObject?>
        let dateArchiveTrigger: Driver<Date>
        let lowerUpperSelectedTrigger: Driver<(Date?, Date?)>
        let buttons: [UIButton]
        let backTrigger: Driver<Void>
        let muteTrigger: Driver<Void>
    }
    
    struct OutputLandscape {
        let selectedDate: Driver<Date?>
        let lowerUpperDates: Driver<(Date?, Date?)>
        let selectedCamera: Driver<CameraExtendedObject?>
        let rangesForCurrentCamera: Driver<[APIArchiveRange]?>
        let events: Driver<EventsDays>
        let isVideoMutted: Driver<Bool>
        let selectedCameraStatus: Driver<Bool?>
    }
    
    struct InputClip {
        let downloadTrigger: Driver<Void>
        let backTrigger: Driver<Void>
        let getSizeTrigger: Driver<Bool>
        let startEndSelectedTrigger: Driver<(Date, Date)>
    }
    
    struct OutputClip {
        let lowerUpperDates: Driver<(Date?, Date?)>
        let selectedDate: Driver<Date?>
        let selectedCamera: Driver<CameraExtendedObject?>
        let events: Driver<EventsDays>
        let clipsize: Driver<String?>
    }
}
// swiftlint:enable function_body_length type_body_length large_tuple
