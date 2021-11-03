//
//  SelectCameraContainerViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 13.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class SelectCameraContainerViewModel: BaseViewModel {
    
    private let address: String
    private let cameras: [CameraObject]
    private let preselectedCamera: CameraObject
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<HomeRoute>
    
    private let selectedCamera: BehaviorSubject<CameraObject?>
    private let rangesForCamera = BehaviorSubject<[APIArchiveRange]?>(value: nil)
    
    private var rangesDisposeBag = DisposeBag()
    private let rangesLoadingTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()
    
    init(
        apiWrapper: APIWrapper,
        address: String,
        cameras: [CameraObject],
        selectedCamera: CameraObject,
        router: WeakRouter<HomeRoute>
    ) {
        self.address = address
        self.cameras = cameras
        self.preselectedCamera = selectedCamera
        self.router = router
        self.apiWrapper = apiWrapper
        
        self.selectedCamera = BehaviorSubject<CameraObject?>(value: selectedCamera)
    }
    
    func transform(_ input: Input) -> Output {
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        input.selectedDateTrigger
            .withLatestFrom(selectedCamera.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .withLatestFrom(rangesForCamera.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (dateAndCamera, ranges) = args
                    let (date, camera) = dateAndCamera
                    
                    guard let uCamera = camera, let uRanges = ranges else {
                        return
                    }
                    
                    self?.router.trigger(.playArchiveVideo(camera: uCamera, date: date, availableRanges: uRanges))
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
        
        selectedCamera
            .asDriver(onErrorJustReturn: nil)
            .do(
                onNext: { [weak self] _ in
                    self?.rangesForCamera.onNext(nil)
                }
            )
            .ignoreNil()
            .drive(
                onNext: { [weak self] camera in
                    self?.updateAvailableDates(camera: camera)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            address: .just(address),
            cameraConfiguration: .just((cameras: cameras, preselectedCamera: preselectedCamera)),
            rangesForCurrentCamera: rangesForCamera.asDriver(onErrorJustReturn: nil),
            areRangesBeingLoaded: rangesLoadingTracker.asDriver()
        )
    }
    
    private func updateAvailableDates(camera: CameraObject) {
        rangesDisposeBag = DisposeBag()
        
        apiWrapper
            .getArchiveRanges(cameraUrl: camera.video, from: 1525186456, token: camera.token)
            .trackActivity(rangesLoadingTracker)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] ranges in
                    self?.rangesForCamera.onNext(ranges)
                }
            )
            .disposed(by: rangesDisposeBag)
    }
    
}

extension SelectCameraContainerViewModel {
    
    struct Input {
        let selectedCameraTrigger: Driver<CameraObject>
        let selectedDateTrigger: Driver<Date>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let address: Driver<String>
        let cameraConfiguration: Driver<(cameras: [CameraObject], preselectedCamera: CameraObject)>
        let rangesForCurrentCamera: Driver<[APIArchiveRange]?>
        let areRangesBeingLoaded: Driver<Bool>
    }
    
}
