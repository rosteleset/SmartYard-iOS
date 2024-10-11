//
//  CityMapViewModel.swift
//  SmartYard
//
//  Created by Александр Васильев on 27.01.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable line_length function_body_length

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import CoreLocation

class CityCameraViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<CityCamsRoute>
    private let camera: CityCameraObject
    private let youTubeVideos = PublishSubject<[YouTubeVideo]>()
    private let reloadingFinishedSubject = PublishSubject<Void>()
    
    init(camera: CityCameraObject, apiWrapper: APIWrapper, router: WeakRouter<CityCamsRoute>) {
        self.camera = camera
        self.apiWrapper = apiWrapper
        self.router = router
    }
    
    fileprivate func loadVideos(errorTracker: ErrorTracker, activityTracker: ActivityTracker, forceRefresh: Bool = false) {
        apiWrapper.getYouTubeVideo(cameraId: camera.id, forceRefresh: forceRefresh)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .delay(.seconds(3))
            .trackActivity(activityTracker)
            .ignoreNil()
            .drive(
                onNext: { [weak self] videos in
                    self?.youTubeVideos.onNext(videos)
                    self?.reloadingFinishedSubject.onNext(())
                }
            )
            .disposed(by: disposeBag)
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
        
        input.videoTrigger
            .drive(
                onNext: { [weak self] urlString in
                    guard let self = self,
                          let url = URL(string: urlString) else {
                        return
                    }
                    self.router.trigger(.youTubeSafari(url: url))
                }
            )
            .disposed(by: disposeBag)
        
        input.requestRecordTrigger
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.router.trigger(.requestRecord(selectedCamera: self.camera))
                }
            )
            .disposed(by: disposeBag)
        
        input.refreshDataTrigger
            .drive(
                onNext: { [weak self] in
                    self?.loadVideos(errorTracker: errorTracker, activityTracker: activityTracker, forceRefresh: true)
                }
            )
            .disposed(by: disposeBag)
        
        loadVideos(errorTracker: errorTracker, activityTracker: activityTracker)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            reloadingFinished: reloadingFinishedSubject.asDriverOnErrorJustComplete(),
            camera: self.camera,
            videos: youTubeVideos.asDriver(onErrorJustReturn: [])
        )
    }
    
}

extension CityCameraViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let videoTrigger: Driver<String>
        let requestRecordTrigger: Driver<Void>
        let refreshDataTrigger: Driver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let reloadingFinished: Driver<Void>
        let camera: CityCameraObject
        let videos: Driver<[YouTubeVideo]>
    }
    
}
// swiftlint:enable line_length function_body_length
