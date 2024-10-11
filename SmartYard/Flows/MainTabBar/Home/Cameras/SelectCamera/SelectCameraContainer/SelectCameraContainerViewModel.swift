//
//  SelectCameraContainerViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 13.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class SelectCameraContainerViewModel: BaseViewModel {
    
    private var address: String = ""
    private var cameras: [CameraObject]
    private var preselectedCamera: CameraObject?
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<HomeRoute>
    
    private let selectedCamera: BehaviorSubject<CameraObject?>
    private let rangesForCamera = BehaviorSubject<[APIArchiveRange]?>(value: nil)
    private let camerasSubject = PublishSubject<[CameraObject]>()
    private let cameraAddress: BehaviorSubject<String>
    private let camerasConfig: BehaviorSubject<(cameras: [CameraObject], preselectedCamera: CameraObject?)>

    private var rangesDisposeBag = DisposeBag()
    private let rangesLoadingTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()
    
    private var houseId: String?
    private var camId: Int?
    
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
        self.cameraAddress = BehaviorSubject<String>(value: address)
        self.camerasConfig = BehaviorSubject<(cameras: [CameraObject], preselectedCamera: CameraObject?)>(value: (cameras: cameras, preselectedCamera: selectedCamera))
    }
    
    init(
        apiWrapper: APIWrapper,
        houseId: String,
        camId: Int?,
        router: WeakRouter<HomeRoute>
    ) {
        self.router = router
        self.houseId = houseId
        self.camId = camId
        self.apiWrapper = apiWrapper
        self.cameras = []
        
        self.selectedCamera = BehaviorSubject<CameraObject?>(value: nil)
        self.cameraAddress = BehaviorSubject<String>(value: "")
        self.camerasConfig = BehaviorSubject<(cameras: [CameraObject], preselectedCamera: CameraObject?)>(value: (cameras: [], preselectedCamera: nil))

    }
    
    func transform(_ input: Input) -> Output {
        let errorTracker = ErrorTracker()
        let activityTracker = ActivityTracker()

        if preselectedCamera == nil, let houseId = houseId {
            apiWrapper.getAllCCTV(houseId: houseId)
                .trackError(errorTracker)
                .trackActivity(activityTracker)
                .asDriver(onErrorJustReturn: nil)
                .ignoreNil()
                .map { response in
                    response.enumerated().map { offset, element in
                        CameraObject(
                            id: element.id,
                            position: element.coordinate,
                            cameraNumber: offset + 1,
                            name: element.name,
                            video: element.video,
                            token: element.token,
                            doors: element.doors.enumerated().map { _, delement in
                                    DoorObject(
                                        domophoneId: delement.domophoneId,
                                        doorId: delement.doorId,
                                        entrance: delement.entrance ?? "",
                                        type: delement.type.iconImageName,
                                        name: delement.name,
                                        blocked: delement.blocked ?? "",
                                        dst: delement.dst ?? ""
                                    )
                            }
                        )
                    }
                }
                .drive(
                    onNext: { [weak self] in
                        self?.camerasSubject.onNext($0)
                    }
                )
                .disposed(by: disposeBag)

            camerasSubject
                .asDriver(onErrorJustReturn: [])
                .drive(
                    onNext: { [weak self] cameras in
                        guard let self = self else {
                            return
                        }
                        self.cameras = cameras
                        
                        if let camId = self.camId {
                            self.preselectedCamera = cameras.first(where: { $0.id == camId })
                        } 
                        if self.preselectedCamera == nil {
                            self.preselectedCamera = cameras.first
                        }
                        
                        self.camerasConfig.onNext((cameras: cameras, preselectedCamera: self.preselectedCamera))
                        if let camera = self.preselectedCamera {
                            self.address = camera.name
                            self.cameraAddress.onNext(camera.name)
                        }
                    }
                )
                .disposed(by: disposeBag)
        }
        
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
        
        input.camSortTrigger
            .flatMapLatest { [weak self] camIds -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper
                        .camSortCCTV(sort: camIds)
                        .trackError(self.errorTracker)
                        .map {_ in 
                            NotificationCenter.default.post(name: .updateCameraOrder, object: nil)
                        }
                        .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive()
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
            address: cameraAddress.asDriver(onErrorJustReturn: ""),
            cameraConfiguration: camerasConfig.asDriverOnErrorJustComplete(),
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
        let camSortTrigger: Driver<[Int]>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let address: Driver<String>
        let cameraConfiguration: Driver<(cameras: [CameraObject], preselectedCamera: CameraObject?)>
        let rangesForCurrentCamera: Driver<[APIArchiveRange]?>
        let areRangesBeingLoaded: Driver<Bool>
    }
    
}
// swiftlint:enable function_body_length
