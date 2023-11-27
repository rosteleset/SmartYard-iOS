//
//  RequestRecordModel.swift
//  SmartYard
//
//  Created by Александр Васильев on 19.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import CoreLocation

class RequestRecordViewModel: BaseViewModel {
    
    private let issueService: IssueService
    private let router: WeakRouter<CityCamsRoute>
    private let camera: CityCameraObject
    
    init(camera: CityCameraObject, issueService: IssueService, router: WeakRouter<CityCamsRoute>) {
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
                    self?.router.trigger(.alert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription))
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
            .flatMapLatest { [weak self] date, duration, notes -> Driver<CreateIssueResponseData?> in
                guard let self = self
                    else {
                    return .empty()
                }
                
                return self.issueService.sendRequestRecIssue(camera: self.camera, date: date, duration: duration, notes: notes ?? "")
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .drive(
                onNext: { response in
                    guard response != nil else {
                        return
                    }
                    
                    self.router.trigger(.back)
                    self.router.trigger(.alert(
                        title: NSLocalizedString("Request submitted", comment: ""),
                        message: NSLocalizedString("We will contact you within 24 hours", comment: "")
                    ))
                }
            )
            .disposed(by: disposeBag)
        
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
