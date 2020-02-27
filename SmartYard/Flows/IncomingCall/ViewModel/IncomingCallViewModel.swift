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

// swiftlint:disable:next type_body_length
class IncomingCallViewModel: BaseViewModel {
    
    private let linphoneService: LinphoneService
    private let apiWrapper: APIWrapper
    
    private let router: WeakRouter<AppRoute>
    
    private let callPayload: CallPayload
    
    private let currentStateSubject = BehaviorSubject<(IncomingCallState, IncomingCallDoorState)>(
        value: (.callReceived, .notDetermined)
    )
    
    private let registrationFinished = BehaviorSubject<Bool>(value: false)
    private let incomingCall = BehaviorSubject<(Call, CallParams)?>(value: nil)
    private let incomingCallAcceptedByUser = BehaviorSubject<Bool>(value: false)
    private let doorOpeningRequestedByUser = BehaviorSubject<Bool>(value: false)
    private let isDoorBeingOpened = BehaviorSubject<Bool>(value: false)
    
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
        
        super.init()
        
        linphoneService.delegate = self
        linphoneService.connect(config: callPayload.sipConfig)
    }
    
    deinit {
        linphoneService.stop()
        linphoneService.hasEnqueuedCalls = false
    }
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func transform(input: Input) -> Output {
        let errorTracker = ErrorTracker()
        
        // MARK: Общий стейт экрана
        
        let currentState = currentStateSubject.asDriverOnErrorJustComplete()
        
        // MARK: проксируем нажатие кнопки "Открыть" в локальный сабжект
        
        input.openTrigger
            .map { true }
            .drive(doorOpeningRequestedByUser)
            .disposed(by: disposeBag)
        
        // MARK: мы можем нажать кнопку "Открыть" еще до того, как примем звонок.
        // Поэтому нам надо будет отложенно выполнить действие по открытию тогда, когда звонок будет принят
        // Именно для этого и используется combineLatest, чтобы выполнить первую проверку после принятия звонка
        // observeOn добавлен для подавления варнинга о циклической зависимости
        // По факту, цикла не будет, тк мы не можем два раза подряд получить один и тот же стейт + мы фильтруем стейты
        
        Driver
            .combineLatest(
                currentStateSubject.observeOn(MainScheduler.asyncInstance).asDriverOnErrorJustComplete(),
                doorOpeningRequestedByUser.asDriver(onErrorJustReturn: false)
            )
            .filter { args in
                let (currentState, isDoorOpeningRequested) = args
                let (callState, doorState) = currentState
                
                return callState == .callAccepted && doorState == .notDetermined && isDoorOpeningRequested
            }
            .mapToVoid()
            .withLatestFrom(incomingCall.asDriver(onErrorJustReturn: nil))
            .ignoreNil()
            .drive(
                onNext: { [weak self] callInfo in
                    guard let self = self else {
                        return
                    }
                    
                    let (call, _) = callInfo
                    self.openTheDoor(call: call)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: После того, как будут выполнены два условия:
        // 1) установлено соединение с SIP-сервером и получен входящий звонок
        // 2) пользователь нажал на кнопку "Ответить", или же пользователь нажал на кнопку "Открыть"
        // Звонок будет Принят и начнется разговор
        
        Driver
            .combineLatest(
                incomingCall.asDriver(onErrorJustReturn: nil),
                incomingCallAcceptedByUser.asDriver(onErrorJustReturn: false),
                doorOpeningRequestedByUser.asDriver(onErrorJustReturn: false)
            )
            .flatMap { args -> Driver<(Call, CallParams)> in
                let (incomingCall, isAccepted, isDoorOpeningRequested) = args
                
                guard let call = incomingCall, (isAccepted || isDoorOpeningRequested) else {
                    return .empty()
                }
                
                return .just(call)
            }
            .throttle(.never)
            .withLatestFrom(currentStateSubject.asDriverOnErrorJustComplete()) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (callInfo, currentState) = args
                    let (_, doorState) = currentState
                    let (call, callParams) = callInfo
                    
                    do {
                        try call.acceptWithParams(params: callParams)
                        self?.currentStateSubject.onNext((.callAccepted, doorState))
                    } catch {
                        self?.router.trigger(.dismiss)
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Если после того, как мы установили соединение, за 2 секунды не придет звонок - закрываем окно
        
        registrationFinished
            .asDriver(onErrorJustReturn: false)
            .isTrue()
            .delay(.milliseconds(2000))
            .withLatestFrom(incomingCall.asDriver(onErrorJustReturn: nil))
            .filter { $0 == nil }
            .withLatestFrom(currentState)
            .do(
                onNext: { [weak self] currentState in
                    let (callState, doorState) = currentState
                    
                    guard let self = self, callState != .callFinished, doorState == .notDetermined else {
                        return
                    }
                    
                    self.currentStateSubject.onNext((.callFinished, doorState))
                    self.linphoneService.stop()
                    self.linphoneService.hasEnqueuedCalls = false
                }
            )
            .delay(.milliseconds(2000))
            .drive(
                onNext: { [weak self] _ in
                    self?.router.trigger(.dismiss)
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
                    self.linphoneService.setViews(videoView: videoView, cameraView: cameraView)
                    self.incomingCallAcceptedByUser.onNext(true)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на кнопку "Игнорировать / Отклонить"
        // Если мы еще не приняли звонок, то просто закрываем окно (человек у домофона думает, что нас нет дома)
        // Если мы уже приняли звонок и жмем "Отклонить", то завершаем звонок и закрываем окно
        
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
            .withLatestFrom(incomingCall.asDriver(onErrorJustReturn: nil))
            .drive(
                onNext: { [weak self] callInfo in
                    guard let self = self else {
                        return
                    }
                    
                    guard let currentCall = callInfo?.0,
                        (currentCall.state == .Connected || currentCall.state == .StreamsRunning) else {
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
        // TODO: Поменять на обычный image, когда его будут присылать нормально
        
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
        
        let callStartedEvent = currentStateSubject
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
        
        let callTimeCounter = callStartedEvent
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
        
        // MARK: Обработка ошибок
        
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
            isDoorBeingOpened: isDoorBeingOpened.asDriver(onErrorJustReturn: false)
        )
    }
    
    private func openTheDoor(call: Call) {
        isDoorBeingOpened.onNext(true)
        
        do {
            try call.sendDtmfs(dtmfs: self.callPayload.dtmf)
        } catch {
            isDoorBeingOpened.onNext(false)
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            print("DTMF code was sent. Delivery is not guaranteed tho")
            
            self?.isDoorBeingOpened.onNext(false)
            self?.currentStateSubject.onNext((.callFinished, .opened))
            
            do {
                try call.terminate()
            } catch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            }
        }
    }
    
}

extension IncomingCallViewModel: LinphoneDelegate {
    
    func onRegistrationStateChanged(lc: Core, cfg: ProxyConfig, cstate: RegistrationState, message: String) {
        print("DEBUG / REGISTRATION STATE: \(cstate)")
        
        if cstate == .Ok {
            registrationFinished.onNext(true)
        }
    }
    
    func onCallStateChanged(lc: Core, call: Call, cstate: Call.State, message: String) {
        print("DEBUG / CALL STATE: \(cstate)")
        
        if cstate == .IncomingReceived, let params = try? lc.createCallParams(call: call) {
            params.videoEnabled = true
            params.audioEnabled = true
            
            incomingCall.onNext((call, params))
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

// swiftlint:disable:next file_length
}
