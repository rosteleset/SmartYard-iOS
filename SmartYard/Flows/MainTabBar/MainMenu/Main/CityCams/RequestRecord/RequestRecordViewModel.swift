//
//  RequestRecordModel.swift
//  SmartYard
//
//  Created by Александр Васильев on 19.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import CoreLocation

class RequestRecordViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    
    private let issueService: IssueService
    private let router: WeakRouter<CityCamsRoute>
    private let camera: CityCameraObject
    
    init(
        apiWrapper: APIWrapper,
        camera: CityCameraObject,
        issueService: IssueService,
        router: WeakRouter<CityCamsRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.camera = camera
        self.issueService = issueService
        self.router = router
    }
    
    func transform(_ input: Input) -> Output {
        let errorTracker = ErrorTracker()
        let activityTracker = ActivityTracker()
        
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
        
        input.sendRequestTrigger
            .withLatestFrom(Driver.combineLatest(input.date, input.duration, input.notes))
//            .flatMapLatest { [weak self] date, duration, notes -> Driver<CreateIssueResponseData?> in
            .flatMapLatest { [weak self] start, duration, notes -> Driver<(from: String, to: String)> in
                guard let self = self else {
                    return .empty()
                }
                
                let formatter = DateFormatter()
                
                // MARK: А тут сервак жрет строки не в GMT, а в MSK
                
                formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                let end = start.addingTimeInterval(Double(duration) * 60)
                
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
//                    self?.router.trigger(.back)

                }
            )
            .disposed(by: disposeBag)

//                return self.issueService.sendRequestRecIssue(camera: self.camera, date: date, duration: duration, notes: notes ?? "")
//                    .trackError(errorTracker)
//                    .trackActivity(activityTracker)
//                    .asDriver(onErrorJustReturn: nil)
//            }
//            .drive(
//                onNext: { response in
//                    guard response != nil else {
//                        return
//                    }
//                    
//                    self.router.trigger(.back)
//                    self.router.trigger(.alert(title: "Заявка отправлена", message: "Мы свяжемся с Вами в течение суток"))
//                }
//            )
//            .disposed(by: disposeBag)
        
        /*apiWrapper.getYouTubeVideo(cameraId: camera.id)
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] videos in
                    self?.youTubeVideos.onNext(videos)
                }
            )
            .disposed(by: disposeBag)
        */
        
        return Output(
            camera: self.camera
        )
    }
    
}

extension RequestRecordViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let sendRequestTrigger: Driver<Void>
        let date: Driver<Date>
        let duration: Driver<(Int)>
        let notes: Driver<String?>
    }
    
    struct Output {
        let camera: CityCameraObject
        
    }
    
}
// swiftlint:enable line_length
