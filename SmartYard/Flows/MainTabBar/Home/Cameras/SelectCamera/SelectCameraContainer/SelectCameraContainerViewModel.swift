//
//  SelectCameraContainerViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 13.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class SelectCameraContainerViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    private let apiWrapper: APIWrapper
    
    private let address: BehaviorSubject<String>
    private let cameras: BehaviorSubject<[CameraObject]>
    
    init(
        router: WeakRouter<HomeRoute>,
        apiWrapper: APIWrapper,
        address: String,
        cameras: [CameraObject]
    ) {
        self.router = router
        self.apiWrapper = apiWrapper
        self.address = BehaviorSubject<String>(value: address)
        self.cameras = BehaviorSubject<[CameraObject]>(value: cameras)
    }
    
    func transform(_ input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            address: address.asDriverOnErrorJustComplete(),
            cameras: cameras.asDriverOnErrorJustComplete()
        )
    }
    
}

extension SelectCameraContainerViewModel {
    
    struct Input {
        let selectedCameraTrigger: Driver<Int>
        let selectedDateTrigger: Driver<Date?>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let address: Driver<String>
        let cameras: Driver<[CameraObject]>
    }
    
}
