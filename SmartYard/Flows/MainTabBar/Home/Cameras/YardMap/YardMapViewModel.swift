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
                    // TODO: прокинуть номер выбранной камеры
                    let (_, address) = args
                    
                    guard let uAddress = address else {
                        return
                    }
                    
                    self?.router.trigger(.cameraContainer(address: uAddress))
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
    
    func createMockData() -> [MapCameraObject] {
        return [
            MapCameraObject(position: CLLocationCoordinate2DMake(54.307966, 48.390189), cameraNumber: 1),
            MapCameraObject(position: CLLocationCoordinate2DMake(54.308001, 48.390666), cameraNumber: 2),
            MapCameraObject(position: CLLocationCoordinate2DMake(54.308062, 48.391106), cameraNumber: 3),
            MapCameraObject(position: CLLocationCoordinate2DMake(54.308100, 48.391543), cameraNumber: 4),
            MapCameraObject(position: CLLocationCoordinate2DMake(54.308170, 48.390905), cameraNumber: 5)
        ]
    }
    
}

extension YardMapViewModel {
    
    struct Input {
        let cameraSelected: Driver<String?>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let cameras: Driver<[MapCameraObject]>
        let centerCoordinates: Driver<CLLocationCoordinate2D?>
        let address: Driver<String?>
    }
    
}
