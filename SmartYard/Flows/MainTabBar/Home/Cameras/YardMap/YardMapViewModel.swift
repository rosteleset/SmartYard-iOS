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
                    let (cameraNum, address) = args
                    
                    guard let self = self, let uAddress = address else {
                        return
                    }
                    
                    self.router.trigger(
                        .cameraContainer(
                            address: uAddress,
                            cameras: self.createMockData(),
                            selectedCameraNumber: cameraNum
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
            address: address.asDriverOnErrorJustComplete()
        )
    }
    
    func createMockData() -> [CameraObject] {
        let url1 = "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8"
        let url2 = "http://playertest.longtailvideo.com/adaptive/oceans_aes/oceans_aes.m3u8"
        let url3 = "https://mnmedias.api.telequebec.tv/m3u8/29880.m3u8"
        
        return [
            CameraObject(position: CLLocationCoordinate2DMake(54.307966, 48.390189), cameraNumber: 1, hlsString: url1),
            CameraObject(position: CLLocationCoordinate2DMake(54.308001, 48.390666), cameraNumber: 2, hlsString: url2),
            CameraObject(position: CLLocationCoordinate2DMake(54.308062, 48.391106), cameraNumber: 3, hlsString: url3),
            CameraObject(position: CLLocationCoordinate2DMake(54.308100, 48.391543), cameraNumber: 4, hlsString: url1),
            CameraObject(position: CLLocationCoordinate2DMake(54.308170, 48.390905), cameraNumber: 5, hlsString: url2),
            CameraObject(position: CLLocationCoordinate2DMake(54.308216, 48.390616), cameraNumber: 6, hlsString: url3),
            CameraObject(position: CLLocationCoordinate2DMake(54.308261, 48.391831), cameraNumber: 7, hlsString: url1),
            CameraObject(position: CLLocationCoordinate2DMake(54.308175, 48.390227), cameraNumber: 8, hlsString: url2),
            CameraObject(position: CLLocationCoordinate2DMake(54.308366, 48.390522), cameraNumber: 9, hlsString: url3),
            CameraObject(position: CLLocationCoordinate2DMake(54.308532, 48.390522), cameraNumber: 10, hlsString: url1)
        ]
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
    }
    
}
