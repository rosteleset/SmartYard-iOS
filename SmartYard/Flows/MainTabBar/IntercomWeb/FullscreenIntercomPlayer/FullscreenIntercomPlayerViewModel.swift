//
//  YardMapViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import Foundation
import XCoordinator
import RxSwift
import RxCocoa

class FullscreenIntercomViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let houseId: String
    private let camId: Int
    private let router: WeakRouter<IntercomWebRoute>
    
    private let cameras = PublishSubject<[CameraObject]>()

    init(
        apiWrapper: APIWrapper,
        houseId: String,
        camId: Int,
        router: WeakRouter<IntercomWebRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.houseId = houseId
        self.camId = camId
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
        
        apiWrapper.getCamCCTV(camId: camId)
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
                    self?.cameras.onNext($0)
                }
            )
            .disposed(by: disposeBag)
        
        input.cameraTrigger
            .drive(
                onNext: { [weak self] camera in
                    print("DEBUG CAMERA", camera)
//                    self?.cameras.onNext($0)
                }
            )

//                    self.router.trigger(
//                        .cameraContainer(
//                            address: uAddress,
//                            cameras: cameras,
//                            selectedCamera: selectedCamera
//                        )
//                    )
            .disposed(by: disposeBag)

        return Output(
            cameras: cameras.asDriver(onErrorJustReturn: []),
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension FullscreenIntercomViewModel {
    
    struct Input {
        let cameraTrigger: Driver<Int>
    }
    
    struct Output {
        let cameras: Driver<[CameraObject]>
        let isLoading: Driver<Bool>
    }
    
}
// swiftlint:enable function_body_length
