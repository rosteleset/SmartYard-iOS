//
//  IncomingCallViewModel.swift
//  SmartYard
//
//  Created by admin on 04/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Kingfisher
import RxSwift
import RxCocoa
import UIKit
import linphonesw
import XCoordinator

class IncomingCallViewModel: BaseViewModel {
    
    private let linphoneService: LinphoneService
    private let callPayload: CallPayload
    private let router: WeakRouter<AppRoute>
    
    private let latestPreview = BehaviorSubject<UIImage?>(value: nil)
    
    init(linphoneService: LinphoneService, callPayload: CallPayload, router: WeakRouter<AppRoute>) {
        self.linphoneService = linphoneService
        self.callPayload = callPayload
        self.router = router
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let currentStateSubject = BehaviorSubject<(IncomingCallState, IncomingCallDoorState)>(
            value: (.callReceived, .notDetermined)
        )
        
        let currentState = currentStateSubject.asDriverOnErrorJustComplete()
        
        let subtitleSubject = BehaviorSubject<String?>(value: callPayload.domophoneString)
        let subtitle = subtitleSubject.asDriver(onErrorJustReturn: nil)
        
        input.previewTrigger
            .withLatestFrom(currentState)
            .drive(
                onNext: { currentState in
                    let (callState, doorState) = currentState
                    
                    guard doorState == .notDetermined else {
                        return
                    }
                    
                    switch callState {
                    case .callReceived: currentStateSubject.onNext((.callPreviewed, doorState))
                    case .callPreviewed: currentStateSubject.onNext((.callReceived, doorState))
                    default: break
                    }
                }
            )
            .disposed(by: disposeBag)
        
        input.callTrigger
            .withLatestFrom(currentState)
            .drive(
                onNext: { currentState in
                    let (callState, doorState) = currentState
                    
                    guard callState != .callAccepted, doorState == .notDetermined else {
                        return
                    }
                    
                    currentStateSubject.onNext((.callAccepted, doorState))
                }
            )
            .disposed(by: disposeBag)
        
        input.openTrigger
            .withLatestFrom(currentState)
            .do(
                onNext: { currentState in
                    let (callState, doorState) = currentState
                    
                    guard doorState == .notDetermined else {
                        return
                    }
                    
                    currentStateSubject.onNext((callState, .opened))
                }
            )
            .delay(.milliseconds(2000))
            .drive(
                onNext: { [weak self] _ in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        input.ignoreTrigger
            .withLatestFrom(currentState)
            .drive(
                onNext: { [weak self] currentState in
                    let (callState, doorState) = currentState
                    
                    guard doorState == .notDetermined else {
                        return
                    }
                    
                    currentStateSubject.onNext((callState, .locked))
                    
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(state: currentState, subtitle: subtitle)
//        let snapshot = BehaviorSubject<UIImage?>(value: nil)
//
//        let loadNextImageTrigger = PublishSubject<Void>()
//
//        Observable
//            .merge(
//                loadNextImageTrigger,
//                .just(())
//            )
//            .delay(.milliseconds(250), scheduler: MainScheduler.instance)
//            .subscribe(
//                onNext: { _ in
//                    KingfisherManager.shared.retrieveImage(
//                        with: liveUrl,
//                        options: [.forceRefresh]
//                    ) { [weak self] result in
//                        if let image = try? result.get().image {
//                            self?.latestPreview.onNext(image)
//                        }
//
//                        loadNextImageTrigger.onNext(())
//                    }
//                }
//            )
//            .disposed(by: disposeBag)
//
//        return Output(image: snapshot, liveImage: )
    }
    
}

extension IncomingCallViewModel {
    
    struct Input {
        let previewTrigger: Driver<Void>
        let callTrigger: Driver<Void>
        let ignoreTrigger: Driver<Void>
        let openTrigger: Driver<Void>
    }
    
    struct Output {
        let state: Driver<(IncomingCallState, IncomingCallDoorState)>
        let subtitle: Driver<String?>
//        let image: Driver<UIImage?>
//        let liveImage: Driver<UIImage?>
    }
    
}
