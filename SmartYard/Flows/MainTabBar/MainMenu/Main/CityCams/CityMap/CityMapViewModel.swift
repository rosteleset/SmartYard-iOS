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

class CityMapViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<CityCamsRoute>
    
    private let cameras = BehaviorSubject<[CityCameraObject]>(value: [])
    
    init(apiWrapper: APIWrapper, router: WeakRouter<CityCamsRoute>) {
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
        
        input.cameraSelected
            .withLatestFrom(cameras.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (cameraNum, cameras) = args
                    
                    guard let self = self,
                        let selectedCamera = (cameras.first { $0.cameraNumber == cameraNum })
                    else {
                        return
                    }
                    self.router.trigger(
                        .cameraContainer(
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
        
        apiWrapper.getOverviewCCTV()
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .map { response in
                response.enumerated().map { offset, element in
                    CityCameraObject(
                        id: element.id,
                        position: element.coordinate,
                        cameraNumber: offset + 1,
                        name: element.name,
                        video: element.video,
                        token: element.token
                    )
                }
            }
            .drive(
                onNext: { [weak self] in
                    self?.cameras.onNext($0)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            cameras: cameras.asDriver(onErrorJustReturn: []),
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension CityMapViewModel {
    
    struct Input {
        let cameraSelected: Driver<Int>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let cameras: Driver<[CityCameraObject]>
        let isLoading: Driver<Bool>
    }
    
}

