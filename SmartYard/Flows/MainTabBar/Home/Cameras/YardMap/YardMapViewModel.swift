//
//  YardMapViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import CoreLocation

class YardMapViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let houseId: String
    private let router: WeakRouter<HomeRoute>
    
    private let address: BehaviorSubject<String?>
    private let cameras = BehaviorSubject<[CameraObject]>(value: [])
    
    private let camerasProxy: [CameraObject]?
    
    init(
        apiWrapper: APIWrapper,
        houseId: String,
        address: String?,
        router: WeakRouter<HomeRoute>,
        cameras: [CameraObject]? = nil
    ) {
        self.apiWrapper = apiWrapper
        self.houseId = houseId
        self.router = router
        self.address = BehaviorSubject<String?>(value: address)
        self.camerasProxy = cameras
    }
    
    // swiftlint:disable:next function_body_length
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
        
        input.cameraSelected
            .withLatestFrom(address.asDriverOnErrorJustComplete()) { ($0, $1) }
            .withLatestFrom(cameras.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (firstPack, cameras) = args
                    let (cameraNum, address) = firstPack
                    
                    guard let self = self,
                        let uAddress = address,
                        let selectedCamera = (cameras.first { $0.cameraNumber == cameraNum }) else {
                        return
                    }
                    
                    self.router.trigger(
                        .cameraContainer(
                            address: uAddress,
                            cameras: cameras,
                            selectedCamera: selectedCamera
                        )
                    )
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
        
        if let camerasProxy = camerasProxy {
            self.cameras.onNext(camerasProxy)
        } else {
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
                            serverType: element.serverType,
                            hlsMode: element.hlsMode
                        )
                    }
                }
                .drive(
                    onNext: { [weak self] in
                        self?.cameras.onNext($0)
                    }
                )
            .disposed(by: disposeBag)
        }
        
        return Output(
            cameras: cameras.asDriver(onErrorJustReturn: []),
            address: address.asDriverOnErrorJustComplete(),
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension YardMapViewModel {
    
    struct Input {
        let cameraSelected: Driver<Int>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let cameras: Driver<[CameraObject]>
        let address: Driver<String?>
        let isLoading: Driver<Bool>
    }
    
}
