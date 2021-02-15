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
    public let camera: CityCameraObject
    
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
        
        /*apiWrapper.getOverviewCCTV()
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
        */
        
        return Output(
            //cameras: cameras.asDriver(onErrorJustReturn: []),
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension CityCameraViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
    }
    
}

