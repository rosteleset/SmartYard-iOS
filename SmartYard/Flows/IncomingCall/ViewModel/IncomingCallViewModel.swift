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
    private let apiWrapper: APIWrapper
    
    private let router: WeakRouter<AppRoute>
    
    private let callPayload: CallPayload
    
    private let currentStateSubject = BehaviorSubject<(IncomingCallState, IncomingCallDoorState)>(
        value: (.callReceived, .notDetermined)
    )
    
    private var currentCall: Call?
    
    init(
        linphoneService: LinphoneService,
        apiWrapper: APIWrapper,
        router: WeakRouter<AppRoute>,
        callPayload: CallPayload
    ) {
        self.linphoneService = linphoneService
        self.apiWrapper = apiWrapper
        self.router = router
        self.callPayload = callPayload
    }
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func transform(input: Input) -> Output {
        let doorOpeningActivityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        // MARK: Общий стейт экрана
        
        let currentState = currentStateSubject.asDriverOnErrorJustComplete()
        
        // MARK: Обработка нажатия на кнопку "Глазок"
        
        input.previewTrigger
            .withLatestFrom(currentState)
            .drive(
                onNext: { [weak self] currentState in
                    let (callState, doorState) = currentState
                    
                    guard let self = self, doorState == .notDetermined else {
                        return
                    }
                    
                    switch callState {
                    case .callReceived: self.currentStateSubject.onNext((.callPreviewed, doorState))
                    case .callPreviewed: self.currentStateSubject.onNext((.callReceived, doorState))
                    default: break
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на кнопку "Звонок"
        
        input.callTrigger
            .withLatestFrom(currentState) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (views, currentState) = args
                    let (videoView, cameraView) = views
                    let (callState, doorState) = currentState
                    
                    guard let self = self,
                        callState == .callReceived || callState == .callPreviewed,
                        doorState == .notDetermined else {
                        return
                    }
                    
                    self.currentStateSubject.onNext((.establishingConnection, doorState))
                    
                    self.linphoneService.delegate = self
                    
                    self.linphoneService.connect(
                        config: self.callPayload.sipConfig,
                        videoView: videoView,
                        cameraView: cameraView
                    )
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на кнопку "Открыть"
        
        input.openTrigger
            .withLatestFrom(currentState)
            .flatMapLatest { [weak self] currentState -> Driver<(IncomingCallState, IncomingCallDoorState)?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.openDoor(domophoneId: self.callPayload.domophoneId, doorId: nil)
                    .trackActivity(doorOpeningActivityTracker)
                    .trackError(errorTracker)
                    .map { _ -> (IncomingCallState, IncomingCallDoorState)? in currentState }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .do(
                onNext: { [weak self] currentState in
                    let (callState, doorState) = currentState
                    
                    guard let self = self, callState != .callFinished, doorState == .notDetermined else {
                        return
                    }
                    
                    self.currentStateSubject.onNext((.callFinished, .opened))
                }
            )
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    
                    guard let currentCall = self.currentCall else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                            self?.router.trigger(.dismiss)
                        }
                        
                        return
                    }
                    
                    do {
                        try currentCall.terminate()
                    } catch {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                            self?.router.trigger(.dismiss)
                        }
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на кнопку "Игнорировать / Отклонить"
        
        input.ignoreTrigger
            .withLatestFrom(currentState)
            .do(
                onNext: { [weak self] currentState in
                    let (callState, doorState) = currentState
                    
                    guard let self = self, callState != .callFinished, doorState == .notDetermined else {
                        return
                    }
                    
                    self.currentStateSubject.onNext((.callFinished, .notDetermined))
                }
            )
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    
                    guard let currentCall = self.currentCall else {
                        self.router.trigger(.dismiss)
                        return
                    }
                    
                    do {
                        try currentCall.terminate()
                    } catch {
                        self.router.trigger(.dismiss)
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Картинка в лайв-режиме
        
        let liveImageSubject = BehaviorSubject<UIImage?>(value: nil)
        let liveImage = liveImageSubject.asDriver(onErrorJustReturn: nil)
        
        let loadNextImageTrigger = PublishSubject<Void>()
        let loadNextImage = Driver.merge(loadNextImageTrigger.asDriver(onErrorJustReturn: ()), .just(()))
        
        if let liveUrl = URL(string: callPayload.liveImage) {
            Driver
                .combineLatest(loadNextImage, currentState)
                .filter { args in
                    let (_, currentState) = args
                    let (callState, _) = currentState
                    
                    return callState == .callPreviewed || callState == .callAccepted
                }
                .mapToVoid()
                .drive(
                    onNext: {
                        KingfisherManager.shared.retrieveImage(
                            with: liveUrl,
                            options: [.forceRefresh]
                        ) { result in
                            if let image = try? result.get().image {
                                liveImageSubject.onNext(image)
                            }
                            
                            loadNextImageTrigger.onNext(())
                        }
                    }
                )
                .disposed(by: disposeBag)
        }
        
        // MARK: Загрузка изначальной превьюхи
        
        let initialImageSubject = BehaviorSubject<UIImage?>(value: nil)
        let initialImage = initialImageSubject.asDriver(onErrorJustReturn: nil)
        
        // MARK: Здесь вместо URL liveImage должен использоваться просто image, но он иногда приходит кривой
        if let url = URL(string: callPayload.liveImage) {
            KingfisherManager.shared.retrieveImage(with: url) { result in
                guard let imageResult = try? result.get() else {
                    return
                }
                
                initialImageSubject.onNext(imageResult.image)
            }
        }
        
        // MARK: Если загрузили изначальную превьюху, то ее же используем и как первую картинку лайва
        
        initialImage
            .withLatestFrom(liveImage) { ($0, $1) }
            .drive(
                onNext: { initialImage, liveImage in
                    if liveImage == nil {
                        liveImageSubject.onNext(initialImage)
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Картинка в зависимости от текущего состояния
        
        let image: Driver<UIImage?> = Driver
            .combineLatest(initialImage, liveImage, currentState)
            .map { args in
                let (initialImage, liveImage, currentState) = args
                let (callState, _) = currentState
                
                switch callState {
                case .callReceived: return initialImage
                default: return liveImage
                }
            }
            .distinctUntilChanged()
        
        // MARK: Дополнительный текст. Здесь либо счетчик звонка, либо адрес домофона (он пока нигде не приходит)
        
        let tempAddressString = [callPayload.domophoneString, callPayload.flatString]
            .compactMap { $0 }
            .joined(separator: ". ")
        
        let subtitleSubject = BehaviorSubject<String?>(value: tempAddressString)
        let subtitle = subtitleSubject.asDriver(onErrorJustReturn: nil)
        
        // MARK: Событие начала звонка
        
        let callAcceptedEvent = currentStateSubject
            .filter { currentState in
                let (callState, _) = currentState
                return callState == .callAccepted
            }
            .take(1)
        
        // MARK: Cобытие завершения звонка
        
        let callFinishedEvent = currentStateSubject
            .filter { currentState in
                let (callState, _) = currentState
                return callState == .callFinished
            }
            .take(1)
        
        // MARK: Работа со счетчиком длительности звонка
        
        let callTimeCounter = callAcceptedEvent
            .flatMap { _ -> Observable<String> in
                let counter: Observable<String> = Observable<Int>
                    .interval(.milliseconds(1000), scheduler: MainScheduler.instance)
                    .map { rawSeconds in
                        let minutes = (rawSeconds + 1) / 60
                        let seconds = (rawSeconds + 1) % 60

                        return String(format: "%02d:%02d", minutes, seconds)
                    }
                
                return Observable.merge(.just("00:00"), counter)
            }
        
        let counterDisposable = callTimeCounter
            .subscribe(
                onNext: { text in
                    subtitleSubject.onNext(text)
                }
            )
        
        callFinishedEvent
            .mapToVoid()
            .subscribe(
                onNext: {
                    counterDisposable.dispose()
                }
            )
            .disposed(by: disposeBag)
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            state: currentState,
            subtitle: subtitle,
            image: image,
            isDoorBeingOpened: doorOpeningActivityTracker.asDriver()
        )
    }
    
}

extension IncomingCallViewModel: LinphoneDelegate {
    
    func onRegistrationStateChanged(lc: Core, cfg: ProxyConfig, cstate: RegistrationState, message: String) {
        print("DEBUG / REGISTRATION STATE: \(cstate)")
    }
    
    func onCallStateChanged(lc: Core, call: Call, cstate: Call.State, message: String) {
        print("DEBUG / CALL STATE: \(cstate)")
        
        if cstate == .IncomingReceived, let params = try? lc.createCallParams(call: call) {
            params.videoEnabled = true
            params.audioEnabled = true
            
            currentCall = call
            
            do {
                try call.acceptWithParams(params: params)
                
                let (_, doorState) = try currentStateSubject.value()
                
                currentStateSubject.onNext((.callAccepted, doorState))
            } catch {
                router.trigger(.dismiss)
            }
        }
        
        if cstate == .End {
            if let (_, doorState) = try? currentStateSubject.value() {
                currentStateSubject.onNext((.callFinished, doorState))
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.router.trigger(.dismiss)
            }
        }
    }
    
}
