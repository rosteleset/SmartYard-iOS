//
//  YardMapViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import CoreLocation

class YardMapViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    private let address: BehaviorSubject<String?>
    
    init(router: WeakRouter<HomeRoute>, address: String?) {
        self.router = router
        self.address = BehaviorSubject<String?>(value: address)
    }
    
    func transform(_ input: Input) -> Output {
        input.cameraSelected
            .withLatestFrom(address.asDriverOnErrorJustComplete()) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    // TODO: лучше использовать id камеры
                    let (cameraNum, address) = args
                    
                    guard let self = self, let uAddress = address else {
                        return
                    }
                    
                    self.router.trigger(
                        .cameraContainer(
                            address: uAddress,
                            cameras: self.createMockData(),
                            selectedCamera: cameraNum
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
        
        return Output(
            cameras: Single.just(createMockData()).asDriver(onErrorJustReturn: []),
            centerCoordinates: Single.just(getHomeCoordinates()).asDriver(onErrorJustReturn: nil),
            address: address.asDriverOnErrorJustComplete()
        )
    }
    
    func getHomeCoordinates() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 54.308083, longitude: 48.390917)
    }
    
    func createMockData() -> [CameraObject] {
        return [
            CameraObject(position: CLLocationCoordinate2DMake(54.307966, 48.390189), cameraNumber: 1),
            CameraObject(position: CLLocationCoordinate2DMake(54.308001, 48.390666), cameraNumber: 2),
            CameraObject(position: CLLocationCoordinate2DMake(54.308062, 48.391106), cameraNumber: 3),
            CameraObject(position: CLLocationCoordinate2DMake(54.308100, 48.391543), cameraNumber: 4),
            CameraObject(position: CLLocationCoordinate2DMake(54.308170, 48.390905), cameraNumber: 5),
            CameraObject(position: CLLocationCoordinate2DMake(54.308216, 48.390616), cameraNumber: 6),
            CameraObject(position: CLLocationCoordinate2DMake(54.308261, 48.391831), cameraNumber: 7),
            CameraObject(position: CLLocationCoordinate2DMake(54.308175, 48.390227), cameraNumber: 8),
            CameraObject(position: CLLocationCoordinate2DMake(54.308366, 48.390522), cameraNumber: 9),
            CameraObject(position: CLLocationCoordinate2DMake(54.307966, 48.390189), cameraNumber: 1),
            CameraObject(position: CLLocationCoordinate2DMake(54.308001, 48.390666), cameraNumber: 2),
            CameraObject(position: CLLocationCoordinate2DMake(54.308062, 48.391106), cameraNumber: 3),
            CameraObject(position: CLLocationCoordinate2DMake(54.308100, 48.391543), cameraNumber: 4),
            CameraObject(position: CLLocationCoordinate2DMake(54.308170, 48.390905), cameraNumber: 5),
            CameraObject(position: CLLocationCoordinate2DMake(54.308216, 48.390616), cameraNumber: 6),
            CameraObject(position: CLLocationCoordinate2DMake(54.308261, 48.391831), cameraNumber: 7),
            CameraObject(position: CLLocationCoordinate2DMake(54.308175, 48.390227), cameraNumber: 8),
            CameraObject(position: CLLocationCoordinate2DMake(54.308366, 48.390522), cameraNumber: 9)
        ]
    }
    
}

extension YardMapViewModel {
    
    struct Input {
        let cameraSelected: Driver<String>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let cameras: Driver<[CameraObject]>
        let centerCoordinates: Driver<CLLocationCoordinate2D?>
        let address: Driver<String?>
    }
    
}
