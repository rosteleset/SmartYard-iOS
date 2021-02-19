//
//  CityMapViewModel.swift
//  SmartYard
//
//  Created by Александр Васильев on 27.01.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import CoreLocation

class CityCameraViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<CityCamsRoute>
    private let camera: CityCameraObject
    private let youTubeVideos = BehaviorSubject<[YouTubeVideo]>(value: [])
    
    init(camera: CityCameraObject, apiWrapper: APIWrapper, router: WeakRouter<CityCamsRoute>) {
        self.camera = camera
        self.apiWrapper = apiWrapper
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
        
        apiWrapper.getYouTubeVideo(cameraId: camera.id)
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
        
        
        return Output(
            //cameras: cameras.asDriver(onErrorJustReturn: []),
            isLoading: activityTracker.asDriver(),
            camera: self.camera,
            videos: youTubeVideos.asDriver(onErrorJustReturn: [])
        )
    }
    
}

extension CityCameraViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let videoTrigger: Driver<String>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let camera: CityCameraObject
        let videos: Driver<[YouTubeVideo]>
    }
    
}

