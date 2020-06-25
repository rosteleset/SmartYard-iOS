//
//  PlayArchiveVideoViewModel.swift
//  SmartYard
//
//  Created by admin on 02.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import XCoordinator
import RxSwift
import RxCocoa

class PlayArchiveVideoViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<HomeRoute>
    
    private let date: Date
    private let camera: CameraObject
    
    private let selectedStartEnd = BehaviorSubject<(Date, Date)?>(value: nil)
    private let selectedPeriod = BehaviorSubject<ArchiveVideoHourPeriod?>(value: nil)
    
    init(apiWrapper: APIWrapper, camera: CameraObject, date: Date, router: WeakRouter<HomeRoute>) {
        self.apiWrapper = apiWrapper
        self.router = router
        
        self.camera = camera
        self.date = date
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
                
                return .just((from: start.apiString, to: end.apiString))
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
        
        let videoURL = selectedPeriod
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .map { [weak self] period -> URL? in
                guard let self = self,
                    let urlComps = period.videoUrlComponents else {
                    return nil
                }
                
                let resultingString = self.camera.video + urlComps + "?token=\(self.camera.token)"
                
                return URL(string: resultingString)
            }
        
        let videoThumbnailURL = selectedPeriod
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .map { [weak self] period -> URL? in
                guard let self = self,
                    let urlComps = period.videoThumbnailComponents else {
                    return nil
                }
                
                let resultingString = self.camera.video + urlComps + "?token=\(self.camera.token)"
                
                return URL(string: resultingString)
            }
        
        let screenshotURL = input.screenshotTrigger
            .debounce(.milliseconds(250))
            .distinctUntilChanged()
            .map { [weak self] date -> URL? in
                guard let self = self else {
                    return nil
                }
                
                // MARK: Здесь нам нужно получить дату скриншота
                // Поскольку используется строковый формат, нам не нужно переводить время из МСК в локальное
                // Но сервер для этого запроса почему-то ожидает время по UTC
                // Поэтому нам нужно отнять разницу между МСК и UTC, чтобы получить правильный скриншот
                
                let utcDate = date.adding(.hour, value: -Date.moscowOffsetFromGMT)
                
                let dateFormatter = DateFormatter()
                
                dateFormatter.dateFormat = "yyyy/MM/dd/HH/mm/ss"
                
                let resultingString = self.camera.video +
                    "/" +
                    dateFormatter.string(from: utcDate) +
                    "-preview.mp4" +
                    "?token=\(self.camera.token)"
                
                return URL(string: resultingString)
            }
        
        let periods: [ArchiveVideoHourPeriod] = (0...7).map {
            ArchiveVideoHourPeriod(baseDate: date, startHours: $0 * 3, endHours: $0 * 3 + 3)
        }
        
        return Output(
            date: .just(date),
            periodConfiguration: .just(periods),
            videoURL: videoURL,
            videoThumbnailURL: videoThumbnailURL,
            screenshotURL: screenshotURL,
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension PlayArchiveVideoViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let downloadTrigger: Driver<Void>
        let periodSelectedTrigger: Driver<ArchiveVideoHourPeriod?>
        let startEndSelectedTrigger: Driver<(Date, Date)>
        let screenshotTrigger: Driver<Date>
    }
    
    struct Output {
        let date: Driver<Date?>
        let periodConfiguration: Driver<[ArchiveVideoHourPeriod]>
        let videoURL: Driver<URL?>
        let videoThumbnailURL: Driver<URL?>
        let screenshotURL: Driver<URL?>
        let isLoading: Driver<Bool>
    }
    
}
