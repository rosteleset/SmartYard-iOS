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
    
    private let selectedStartEnd = BehaviorSubject<(Float64, Float64)?>(value: nil)
    private let selectedPeriod = BehaviorSubject<ArchiveVideoHourPeriod?>(value: nil)
    
    init(camera: CameraObject, date: Date, router: WeakRouter<HomeRoute>) {
        self.router = router
        
        self.camera = camera
        self.date = date
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
        
        input.startEndSelectedTrigger
            .drive(
                onNext: { [weak self] in
                    self?.selectedStartEnd.onNext(($0))
                }
            )
            .disposed(by: disposeBag)
        
        input.downloadTrigger
            .withLatestFrom(selectedPeriod.asDriver(onErrorJustReturn: nil))
            .withLatestFrom(selectedStartEnd.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMap { args -> Driver<(from: String, to: String)> in
                let (period, startEnd) = args
                
                guard let uPeriod = period, let uStartEnd = startEnd else {
                    return .empty()
                }
                
                let (start, end) = uStartEnd
                
                guard end - start > 0,
                    let recPrepareComps = uPeriod.recPrepareComponents(start: start, end: end) else {
                    return .empty()
                }
                
                return .just(recPrepareComps)
            }
            .drive(
                onNext: { [weak self] comps in
                    print(comps.from)
                    print(comps.to)
                }
            )
            .disposed(by: disposeBag)
        
        let videoURL = selectedPeriod
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .map { [weak self] period -> URL? in
                guard let self = self,
                    let urlComps = period.videoUrlComponents else {
                    return nil
                }
                
                let stringUrl = self.camera.video.absoluteString.replacingOccurrences(
                    of: "index.m3u8",
                    with: urlComps
                )
                
                return URL(string: stringUrl)
            }
        
        let periods: [ArchiveVideoHourPeriod] = (0...23).map {
            ArchiveVideoHourPeriod(baseDate: date, startHours: $0 * 1, endHours: $0 * 1 + 1)
        }
        
        return Output(
            date: .just(date),
            periodConfiguration: .just(periods),
            videoURL: videoURL,
            preview: .just(camera.preview)
        )
    }
    
}

extension PlayArchiveVideoViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let downloadTrigger: Driver<Void>
        let periodSelectedTrigger: Driver<ArchiveVideoHourPeriod?>
        let startEndSelectedTrigger: Driver<(Float64, Float64)>
    }
    
    struct Output {
        let date: Driver<Date?>
        let periodConfiguration: Driver<[ArchiveVideoHourPeriod]>
        let videoURL: Driver<URL?>
        let preview: Driver<URL?>
    }
    
}
