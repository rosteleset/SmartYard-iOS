//
//  PlayArchiveVideoViewModel.swift
//  SmartYard
//
//  Created by admin on 02.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import XCoordinator
import RxSwift
import RxCocoa

class PlayArchiveVideoViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    
    private let date: Date
    private let camera: CameraObject
    
    private let selectedPeriod: BehaviorSubject<ArchiveVideoHourPeriod?>
    
    init(camera: CameraObject, date: Date, router: WeakRouter<HomeRoute>) {
        self.router = router
        
        self.camera = camera
        self.date = date
        
        self.selectedPeriod = BehaviorSubject<ArchiveVideoHourPeriod?>(value: nil)
    }
    
    func transform(_ input: Input) -> Output {
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        input.periodSelectedTrigger
            .drive(
                onNext: { [weak self] in
                    self?.selectedPeriod.onNext($0)
                }
            )
            .disposed(by: disposeBag)
        
        let videoURL = selectedPeriod
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .map { [weak self] period -> URL? in
                guard let self = self else {
                    return nil
                }
                
                let stringUrl = self.camera.video.absoluteString.replacingOccurrences(
                    of: "index.m3u8",
                    with: period.videoUrlComponents
                )
                
                return URL(string: stringUrl)
            }
        
        let periods: [ArchiveVideoHourPeriod] = (0...7).map {
            ArchiveVideoHourPeriod(baseDate: date, startHours: $0 * 3, endHours: $0 * 3 + 3)
        }
        
        return Output(
            date: .just(date),
            periodConfiguration: .just(periods),
            videoURL: videoURL
        )
    }
    
}

extension PlayArchiveVideoViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let periodSelectedTrigger: Driver<ArchiveVideoHourPeriod?>
    }
    
    struct Output {
        let date: Driver<Date?>
        let periodConfiguration: Driver<[ArchiveVideoHourPeriod]>
        let videoURL: Driver<URL?>
    }
    
}
