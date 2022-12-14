//
//  PlayArchiveVideoViewModel.swift
//  SmartYard
//
//  Created by admin on 02.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import XCoordinator
import RxSwift
import RxCocoa
import AVKit

class PlayArchiveVideoViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<HomeRoute>
    
    private let date: Date
    private let ranges: [APIArchiveRange]
    private let camera: CameraObject
    
    private let selectedStartEnd = BehaviorSubject<(Date, Date)?>(value: nil)
    private let selectedPeriod = BehaviorSubject<ArchiveVideoPreviewPeriod?>(value: nil)
    
    init(
        apiWrapper: APIWrapper,
        camera: CameraObject,
        date: Date,
        availableRanges: [APIArchiveRange],
        router: WeakRouter<HomeRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.router = router
        
        self.camera = camera
        self.date = date
        self.ranges = availableRanges
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        let errorTracker = ErrorTracker()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        let activityTracker = ActivityTracker()
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        input.periodSelectedTrigger
            .drive(
                onNext: { [weak self] in
                    self?.selectedPeriod.onNext($0)
                }
            )
            .disposed(by: disposeBag)
        
        input.startEndSelectedTrigger
            .drive(
                onNext: { [weak self] in
                    self?.selectedStartEnd.onNext(($0))
                }
            )
            .disposed(by: disposeBag)
        
        input.downloadTrigger
            .withLatestFrom(selectedStartEnd.asDriver(onErrorJustReturn: nil))
            .flatMap { args -> Driver<(from: String, to: String)> in
                guard let uArgs = args else {
                    return .empty()
                }
                
                let (start, end) = uArgs
                
                guard end > start else {
                    return .empty()
                }
                
                let formatter = DateFormatter()
                
                // MARK: А тут сервак жрет строки не в GMT, а в MSK
                
                formatter.timeZone = Calendar.moscowCalendar.timeZone
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                return .just((from: formatter.string(from: start), to: formatter.string(from: end)))
            }
            .flatMapLatest { [weak self] range -> Driver<Int?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .recPrepare(id: self.camera.id, from: range.from, to: range.to)
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .flatMapLatest { [weak self] fragmentId -> Driver<RecDownloadResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .recDownload(id: fragmentId)
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
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
        
        let videoData = selectedPeriod
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .map { [weak self] period -> ([URL], VideoThumbnailConfiguration)? in
                guard let self = self,
                      let fallbackUrl = URL(string: self.camera.previewMP4URL) else {
                    return nil
                }
                
                // передаём массив компонетов URL для всех фрагментов
                let videoUrl = period.videoUrlComponentsArray.map { videoUrlComps -> URL in
                    let url = URL(string: self.camera.archiveURL(urlComponents: videoUrlComps))
                    return url!
                }
                
                let thumbnailConfig = VideoThumbnailConfiguration(
                    camera: self.camera,
                    period: period,
                    fallbackUrl: fallbackUrl
                )
                
                return (videoUrl, thumbnailConfig)
            }
        
        let screenshotURL = input.screenshotTrigger
            .debounce(.milliseconds(250))
            .distinctUntilChanged()
            .map { [weak self] date -> URL? in
                guard let self = self else {
                    return nil
                }
               
                return URL(string: self.camera.previewMP4URL(date))
            }
        
        // определяем границы архива на сервере
        let rangeBounds: (lower: Date, upper: Date)? = {
            guard let lower = (ranges.map { $0.startDate }.min()),
                let upper = (ranges.map { $0.endDate }.max()) else {
                return nil
            }
                
            return (lower, upper)
        }()
        
        // определяем периоды, для которых есть архив на сервере
        var periods = [ArchiveVideoPreviewPeriod]()
        
        let startOfDay = Calendar.moscowCalendar.startOfDay(for: date)
        
        for mult in 0...7 {
            let startHours = mult * 3
            let endHours = mult * 3 + 3
            
            let startDate = startOfDay.adding(.hour, value: startHours)
            let endDate = startOfDay.adding(.hour, value: endHours)
            
            // отбрасываем период, если он целиком заканчивается до времени начала архива
            guard rangeBounds != nil,
                  endDate > rangeBounds!.lower else {
                continue
            }
            
            // filter - отбираем границы всех доступных фрагментов архива на сервере, с которыми пересекается наш период
            // map - подрезаем границы интервалов, выходящих за границы текущего периода
            //      и преобразуем в кортеж (startDate: Date, endDate:end)
            let intersections = ranges
                .filter({ $0.intersects(start: startDate, end: endDate) })
                .map({ (startDate: max($0.startDate, startDate), endDate: min($0.endDate, endDate)) })
            
            guard
                  // получаем границы самого раннего доступного фрагмента на сервере, с которым пересекается наш период
                  let currentRangeFirst = intersections.first,
                  // получаем границы самого позднего доступного фрагмента на сервере, с которым пересекается наш период
                  let currentRangeLast = intersections.last else {
                continue
            }
            
            // добавляем период, при необходимости подрезая концы периода под фактически имеющийся на сервере архив.
            periods.append(
                ArchiveVideoPreviewPeriod(
                    startDate: currentRangeFirst.startDate,
                    endDate: currentRangeLast.endDate,
                    ranges: intersections
                )
            )
        }
        
        return Output(
            date: .just(date),
            periodConfiguration: .just(periods),
            rangeBounds: .just(rangeBounds),
            videoData: videoData,
            screenshotURL: screenshotURL,
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension PlayArchiveVideoViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let downloadTrigger: Driver<Void>
        let periodSelectedTrigger: Driver<ArchiveVideoPreviewPeriod?>
        let startEndSelectedTrigger: Driver<(Date, Date)>
        let screenshotTrigger: Driver<Date>
    }
    
    struct Output {
        let date: Driver<Date?>
        let periodConfiguration: Driver<[ArchiveVideoPreviewPeriod]>
        let rangeBounds: Driver<(lower: Date, upper: Date)?>
        let videoData: Driver<([URL], VideoThumbnailConfiguration)?>
        let screenshotURL: Driver<URL?>
        let isLoading: Driver<Bool>
    }
    
}
