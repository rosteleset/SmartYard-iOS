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

final class PlayArchiveVideoViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<HomeRoute>
    
    private let date: Date
    private let ranges: [APIArchiveRange]
    private let camera: CameraObject
    
    private let selectedStartEnd = BehaviorSubject<(Date, Date)?>(value: nil)
    private let selectedPeriod = BehaviorSubject<ArchiveVideoPreviewPeriod?>(value: nil)
    private let selectedSpeed = BehaviorSubject<ArchiveVideoPlaybackSpeed>(value: .normal)
    
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
                    self?.router.trigger(.alert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        let activityTracker = ActivityTracker()
        let activityVideoTracker = ActivityTracker()
        
        
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
        
        input.speedTrigger
            .distinctUntilChanged()
            .drive(
                onNext: { [weak self] in
                    self?.selectedSpeed.onNext($0)
                    // для перезапуска потока с новой скоростью, самое лёгкое решение - вызвать перемотку на 0 секунд.
                    NotificationCenter.default.post(name: .videoPlayerSeek, object: 0)
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
                
                formatter.timeZone = Calendar.serverCalendar.timeZone
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
                        let msg = NSLocalizedString("As soon as the process is over...", comment: "")
                        
                        let okAction = UIAlertAction(title: NSLocalizedString("Thank you", comment: ""), style: .default, handler: nil)
                        
                        self?.router.trigger(
                            .dialog(
                                title: NSLocalizedString("Video in progress", comment: ""),
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
                                    title: NSLocalizedString("Link to video copied to clipboard", comment: ""),
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
        
        let videoDataFromSelectedPeriod = selectedPeriod
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .flatMap { [weak self] period -> Driver<([URL], VideoThumbnailConfiguration?)?> in
                guard let self = self else {
                        return .just(nil)
                }
                return self.camera.dataModelForArchive(period: period)
                    .map { $0.optional }
            }
            .trackActivity(activityVideoTracker)
            
        let videoDataFromSeek = input.seekToTrigger
            .withLatestFrom(selectedPeriod.asDriverOnErrorJustComplete()) { ($0, $1) }
            .withLatestFrom(selectedSpeed.asDriverOnErrorJustComplete()) { ($0.0, $0.1, $1) }
            .asDriver()
            .flatMap { [weak self] newPos, period, speed -> Driver<([URL], VideoThumbnailConfiguration?)?> in
                guard let self = self, let period = period else {
                        return .just(nil)
                }
                
                let observable = Single<String>.create { single in
                    self.camera.getArchiveVideo(
                        startDate: newPos,
                        endDate: period.endDate,
                        speed: speed.value
                    ) { urlString in
                        guard let urlString = urlString else {
                            single(.failure(NSError.APIWrapperError.noDataError))
                            return
                        }
                        single(.success(urlString))
                    }
                    
                    return Disposables.create { return }
                }
                .map { urlString -> ([URL], VideoThumbnailConfiguration?)? in
                    guard let url = URL(string: urlString) else {
                        return ([], nil)
                    }
                    return ([url], nil)
                }
                return observable.asDriver(onErrorJustReturn: nil)
            }
            .trackActivity(activityVideoTracker)
        
        let videoData = Driver.merge(videoDataFromSelectedPeriod, videoDataFromSeek)
        
        let screenshotURL = input.screenshotTrigger
            .debounce(.milliseconds(250))
            .distinctUntilChanged()
            .map { [weak self] date -> (url: URL?, imageType: SYImageType) in
                guard let self = self else {
                    return (nil, .mp4)
                }
                let imageType: SYImageType = {
                    switch self.camera.serverType {
                    case .forpost:
                        return .jpegLink
                    case .macroscop, .trassir:
                        return .jpeg
                    default:
                        return .mp4
                    }
                } ()
                
                return (
                    url: URL(string: self.camera.previewURL(date)),
                    imageType: imageType
                )
            }
        let hasSound = BehaviorSubject<Bool>(value: self.camera.hasSound )
        let rangeBoundsSubject = BehaviorSubject<(lower: Date, upper: Date)?>(value: nil)
        let periodsSubject = BehaviorSubject<[ArchiveVideoPreviewPeriod]>(value: [])
        
        print(#line, hasSound)
        print(#line, hasSound)
        
        camera.requestRanges(for: date, ranges: ranges) { [weak self] ranges in
            guard let self = self else { return }
            
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
            
            let startOfDay = Calendar.serverCalendar.startOfDay(for: self.date)
            
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
        
                rangeBoundsSubject.onNext(rangeBounds)
                periodsSubject.onNext(periods)
            }
        }

        return Output(
            date: .just(date),
            periodConfiguration: periodsSubject.asDriverOnErrorJustComplete(), // .just(periods),
            rangeBounds: rangeBoundsSubject.asDriverOnErrorJustComplete(), // .just(rangeBounds),
            videoData: videoData,
            screenshotURL: screenshotURL,
            isLoading: activityTracker.asDriver(),
            isVideoLoading: activityVideoTracker.asDriver(),
            hasSound: hasSound.asDriverOnErrorJustComplete()
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
        let seekToTrigger: Driver<Date>
        let speedTrigger: Driver<ArchiveVideoPlaybackSpeed>
    }
    
    struct Output {
        let date: Driver<Date?>
        let periodConfiguration: Driver<[ArchiveVideoPreviewPeriod]>
        let rangeBounds: Driver<(lower: Date, upper: Date)?>
        let videoData: Driver<([URL], VideoThumbnailConfiguration?)?>
        let screenshotURL: Driver<(url: URL?, imageType: SYImageType)>
        let isLoading: Driver<Bool>
        let isVideoLoading: Driver<Bool>
        let hasSound: Driver<Bool>
    }
    
}
