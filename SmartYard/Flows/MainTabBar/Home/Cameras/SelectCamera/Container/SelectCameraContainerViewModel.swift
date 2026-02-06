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

final class SelectCameraContainerViewModel: BaseViewModel {

    private let address: String
    private let cameras: [CameraObject]
    private let preselectedCameraId: CameraID

    private let camerasById: [CameraID: CameraObject]

    private let apiWrapper: APIWrapper
    private let router: WeakRouter<HomeRoute>

    private let selectedCameraId: BehaviorSubject<CameraID?>
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
        let cameras = cameras
        self.address = address
        self.cameras = cameras
        self.preselectedCameraId = selectedCamera.id
        self.camerasById = Dictionary(uniqueKeysWithValues: cameras.map { ($0.id, $0) })

        self.router = router
        self.apiWrapper = apiWrapper

        self.selectedCameraId = BehaviorSubject<CameraID?>(value: selectedCamera.id)
    }

    func transform(_ input: Input) -> Output {

        input.backTrigger
            .drive(onNext: { [weak self] in
                self?.router.trigger(.back)
            })
            .disposed(by: disposeBag)

        input.selectedCameraIdTrigger
            .drive { [weak self] id in
                self?.selectedCameraId.onNext(id)
            }
            .disposed(by: disposeBag)

        selectedCameraId
            .asDriver(onErrorJustReturn: nil)
            .distinctUntilChanged()
            .do { [weak self] _ in
                self?.rangesForCamera.onNext(nil)
            }
            .ignoreNil()
            .drive { [weak self] id in
                guard let self, let camera = camerasById[id] else { return }
                updateAvailableDates(camera: camera)
            }
            .disposed(by: disposeBag)

        input.selectedDateTrigger
            .withLatestFrom(selectedCameraId.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .withLatestFrom(rangesForCamera.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .drive(onNext: { [weak self] args in
                guard let self else { return }

                let (dateAndId, ranges) = args
                let (date, cameraId) = dateAndId

                guard
                    let cameraId,
                    let camera = self.camerasById[cameraId],
                    let ranges
                else { return }

                router.trigger(
                    .playArchiveVideo(
                        camera: camera,
                        date: date,
                        availableRanges: ranges
                    )
                )
            })
            .disposed(by: disposeBag)

        return Output(
            address: .just(address),
            cameraConfiguration: .just((cameras: cameras, preselectedCameraId: preselectedCameraId)),
            rangesForCurrentCamera: rangesForCamera.asDriver(onErrorJustReturn: nil),
            areRangesBeingLoaded: rangesLoadingTracker.asDriver()
        )
    }

    private func updateAvailableDates(camera: CameraObject) {
        rangesDisposeBag = DisposeBag()

        apiWrapper
            .getArchiveRanges(camera)
            .trackActivity(rangesLoadingTracker)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive { [weak self] ranges in
                self?.rangesForCamera.onNext(ranges)
            }
            .disposed(by: rangesDisposeBag)
    }
}

extension SelectCameraContainerViewModel {
    struct Input {
        let selectedCameraIdTrigger: Driver<CameraID>
        let selectedDateTrigger: Driver<Date>
        let backTrigger: Driver<Void>
    }

    struct Output {
        let address: Driver<String>
        let cameraConfiguration: Driver<(cameras: [CameraObject], preselectedCameraId: CameraID)>
        let rangesForCurrentCamera: Driver<[APIArchiveRange]?>
        let areRangesBeingLoaded: Driver<Bool>
    }
}
