//
//  IncomingCallViewModel.swift
//  SmartYard
//
//  Created by admin on 04/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable type_body_length function_body_length cyclomatic_complexity
// swiftlint:disable closure_body_length line_length file_length

import Kingfisher
import RxSwift
import RxCocoa
import UIKit
import linphonesw
import XCoordinator
import AVFoundation
import CallKit

class IncomingCallViewModel: BaseViewModel {
    
    private let providerProxy: CXProviderProxy
    private let linphoneService: LinphoneService
    private let permissionService: PermissionService
    private let apiWrapper: APIWrapper
    private let pushNotificationService: PushNotificationService
    
    private let router: WeakRouter<AppRoute>
    
    private let callPayload: CallPayload
    
    private let currentStateSubject: BehaviorSubject<IncomingCallStateContainer>
    
    private let errorTracker = ErrorTracker()
    
    private let registrationFinished = BehaviorSubject<Bool>(value: false)
    private let incomingCall = BehaviorSubject<(Call, CallParams)?>(value: nil)
    private let incomingCallAcceptedByUser = BehaviorSubject<Bool>(value: false)
    private let doorOpeningRequestedByUser = BehaviorSubject<Bool>(value: false)
    private let isDoorBeingOpened = BehaviorSubject<Bool>(value: false)
    
    // MARK: По умолчанию звонок принятый через CallKit должен показываться со статичной картинкой
    // Чтобы показалось видео - нужно, чтобы пользователь нажал на кнопку "Video" в коллките
    // Если CallKit выключен, то всегда по умолчанию показывается видео
    
    private let preferredPreviewModeForActiveCall: BehaviorSubject<IncomingCallPreviewState>
    private let subtitleSubject: BehaviorSubject<String?>
    private let imageSubject = BehaviorSubject<UIImage?>(value: nil)
    
    private let answerCallProxySubject = PublishSubject<Void>()
    private let endCallProxySubject = PublishSubject<Void>()
    
    /// Название быстрого действия из push-уведомления, которое надо выполнить в этой модели.
    private let actionIdentifier: String
    
    /// Задаётся только, когда модель была вызвана из быстрого действия в push-уведомлении.
    /// Выполняется, когда надо уведомить iOS, что мы закончили выполнять команду
    /// и приложение можно обратно усыпить.
    private var completionHandler: (() -> Void)?
    
    init(
        providerProxy: CXProviderProxy,
        linphoneService: LinphoneService,
        permissionService: PermissionService,
        apiWrapper: APIWrapper,
        pushNotificationService: PushNotificationService,
        router: WeakRouter<AppRoute>,
        callPayload: CallPayload,
        isCallKitUsed: Bool,
        actionIdentifier: String = "",
        completionHandler: (() -> Void)? = nil
    ) {
        self.providerProxy = providerProxy
        self.linphoneService = linphoneService
        self.permissionService = permissionService
        self.apiWrapper = apiWrapper
        self.pushNotificationService = pushNotificationService
        self.router = router
        self.callPayload = callPayload
        self.actionIdentifier = actionIdentifier
        self.completionHandler = completionHandler
        
        preferredPreviewModeForActiveCall = BehaviorSubject<IncomingCallPreviewState>(
            value: isCallKitUsed ? .staticImage : .video
        )
        
        subtitleSubject = BehaviorSubject<String?>(value: callPayload.callerId)
        
        currentStateSubject = BehaviorSubject<IncomingCallStateContainer>(
            value: .getDefaultSpeakerMode(isCallKitUsed, apiWrapper: apiWrapper)
        )
        
        super.init()
        
        linphoneService.delegate = self
        linphoneService.connect(config: callPayload.sipConfig)
        
        providerProxy.delegate = self
        
        createCommonBindings()
    }
    
    deinit {
        UIDevice.current.isProximityMonitoringEnabled = false
        
        try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        
        linphoneService.stop()
        linphoneService.hasEnqueuedCalls = false
    }
    
    // Все, что не зависит от Input, а привязано к локальным сабжектам
    private func createCommonBindings() {
        let currentState = currentStateSubject.asDriverOnErrorJustComplete()
        
        // MARK: Обработка ошибок
        
        let micMsg = "Исходящего звука в этом звонке не будет. " +
        "Чтобы он появился в следующих звонках, предоставьте доступ к микрофону в настройках"
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    if (error as NSError) == NSError.PermissionError.noMicPermission {
                        self?.router.trigger(.alert(title: "Нет доступа к микрофону", message: micMsg))
                        return
                    }
                    
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: мы можем нажать кнопку "Открыть" еще до того, как примем звонок.
        // Поэтому нам надо будет отложенно выполнить действие по открытию тогда, когда звонок будет принят
        // Именно для этого и используется combineLatest, чтобы выполнить первую проверку после принятия звонка
        // observeOn добавлен для подавления варнинга о циклической зависимости
        // По факту, цикла не будет, тк мы не можем два раза подряд получить один и тот же стейт + мы фильтруем стейты
        
        Driver
            .combineLatest(
                currentStateSubject.observe(on: MainScheduler.asyncInstance).asDriverOnErrorJustComplete(),
                doorOpeningRequestedByUser.asDriver(onErrorJustReturn: false)
            )
            .filter { args in
                let (currentState, isDoorOpeningRequested) = args
                
                return currentState.callState == .callActive &&
                    currentState.doorState == .notDetermined &&
                    isDoorOpeningRequested
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
        
        // MARK: Если пользователь нажал на "Принять звонок", проверяем, есть ли у него доступ к микрофону
        // Если нет - кидаем алерт о необходимости включить микрофон для передачи звука
        
        incomingCallAcceptedByUser
            .asDriver(onErrorJustReturn: false)
            .isTrue()
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.permissionService.requestAccessToMic()
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .drive()
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
                
                guard let unwrappedIncomingCall = incomingCall, (isAccepted || isDoorOpeningRequested) else {
                    return .empty()
                }
                
                let (call, callParams) = unwrappedIncomingCall
                
                if isDoorOpeningRequested {
                    call.speakerMuted = true
                    call.microphoneMuted = true
                }
                
                return .just((call, callParams))
            }
            .throttle(.never)
            .withLatestFrom(currentStateSubject.asDriverOnErrorJustComplete()) { ($0, $1) }
            .withLatestFrom(preferredPreviewModeForActiveCall.asDriverOnErrorJustComplete()) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    guard let self = self else {
                        return
                    }
                    
                    let (firstPack, previewMode) = args
                    let (callInfo, currentState) = firstPack
                    let (call, callParams) = callInfo
                    
                    do {
                        try call.acceptWithParams(params: callParams)
                        
                        self.providerProxy.updateCall(
                            uuid: self.callPayload.uuid,
                            handle: self.callPayload.callerId,
                            hasVideo: true
                        )
                        
                        UIDevice.current.isProximityMonitoringEnabled = true
                        
                        let soundOutputState: IncomingCallSoundOutputState = {
                            if call.speakerMuted {
                                return .disabled
                            }
                            
                            return currentState.soundOutputState
                        }()
                        let newState = IncomingCallStateContainer(
                            callState: .callActive,
                            doorState: currentState.doorState,
                            previewState: previewMode,
                            soundOutputState: soundOutputState
                        )
                        
                        self.currentStateSubject.onNext(newState)
                    } catch {
                        self.providerProxy.endCall(uuid: self.callPayload.uuid)
                        self.completionHandler?()
                        self.completionHandler = nil
                        self.router.trigger(.closeIncomingCall)
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Если после того, как мы установили соединение, за 3 секунды не придет звонок - закрываем окно
        
        registrationFinished
            .asDriver(onErrorJustReturn: false)
            .isTrue()
            .delay(.milliseconds(5000))
            .withLatestFrom(incomingCall.asDriver(onErrorJustReturn: nil))
            .filter { $0 == nil }
            .withLatestFrom(currentState)
            .do(
                onNext: { [weak self] currentState in
                    guard let self = self,
                        currentState.callState != .callFinished,
                        currentState.doorState == .notDetermined else {
                        return
                    }
                    
                    let newState = IncomingCallStateContainer(
                        callState: .callFinished,
                        doorState: currentState.doorState,
                        previewState: .staticImage,
                        soundOutputState: .disabled
                    )
                    self.currentStateSubject.onNext(newState)
                    
                    self.linphoneService.stop()
                    self.linphoneService.hasEnqueuedCalls = false
                }
            )
            .delay(.milliseconds(2000))
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    
                    self.providerProxy.endCall(uuid: self.callPayload.uuid)
                    self.completionHandler?()
                    self.completionHandler = nil
                    self.router.trigger(.closeIncomingCall)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на кнопку "Video" в CallKit
        
        NotificationCenter.default.rx
            .notification(.videoRequestedByCallKit)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(currentState)
            .drive(
                onNext: { [weak self] currentState in
                    guard let self = self, currentState.doorState == .notDetermined else {
                        return
                    }
                    
                    switch currentState.callState {
                        
                    // MARK: Если звонок активен - то принудительно запускаем видео
                    
                    case .callActive:
                        let newState = IncomingCallStateContainer(
                            callState: currentState.callState,
                            doorState: currentState.doorState,
                            previewState: .video,
                            soundOutputState: currentState.soundOutputState
                        )
                        
                        self.currentStateSubject.onNext(newState)
                        
                    // MARK: Если звонок только пришел, устанавливается соединение - обновляем предпочтение
                        
                    default:
                        self.preferredPreviewModeForActiveCall.onNext(.video)
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
                    
                    return currentState.callState == .callReceived && currentState.previewState == .video
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
                
                switch currentState.previewState {
                case .staticImage: return initialImage
                case .video: return liveImage
                }
            }
            .distinctUntilChanged()
        
        image
            .drive(imageSubject)
            .disposed(by: disposeBag)
        
        // MARK: Событие начала звонка
        
        let callStartedEvent = currentStateSubject
            .filter { currentState in
                currentState.callState == .callActive
            }
            .take(1)
        
        // MARK: Cобытие завершения звонка
        
        let callFinishedEvent = currentStateSubject
            .filter { currentState in
                currentState.callState == .callFinished
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
                onNext: { [weak self] text in
                    self?.subtitleSubject.onNext(text)
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
        
        // MARK: Обработка нажатия на кнопку "Звонок" во вьюхе приложения либо в CallKit
        
        answerCallProxySubject
            .asDriverOnErrorJustComplete()
            .withLatestFrom(currentState)
            .drive(
                onNext: { [weak self] currentState in
                    guard let self = self,
                        currentState.callState == .callReceived,
                        currentState.doorState == .notDetermined else {
                        return
                    }
                    
                    let newState = IncomingCallStateContainer(
                        callState: .establishingConnection,
                        doorState: currentState.doorState,
                        previewState: currentState.previewState,
                        soundOutputState: currentState.soundOutputState
                    )
                    self.currentStateSubject.onNext(newState)
                    
                    self.incomingCallAcceptedByUser.onNext(true)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на кнопку "Игнорировать / Отклонить"
        // Если мы еще не приняли звонок, то просто закрываем окно (человек у домофона думает, что нас нет дома)
        // Если мы уже приняли звонок и жмем "Отклонить", то завершаем звонок и закрываем окно
        // UPD: Сюда же и нажатие на кнопку сброса в нативной вьюхе CallKit
        
        endCallProxySubject
            .asDriverOnErrorJustComplete()
            .withLatestFrom(currentState)
            .do(
                onNext: { [weak self] currentState in
                    guard let self = self,
                        currentState.callState != .callFinished,
                        currentState.doorState == .notDetermined else {
                        return
                    }
                    
                    let newState = IncomingCallStateContainer(
                        callState: .callFinished,
                        doorState: .notDetermined,
                        previewState: .staticImage,
                        soundOutputState: .disabled
                    )
                    
                    self.currentStateSubject.onNext(newState)
                }
            )
            .withLatestFrom(incomingCall.asDriver(onErrorJustReturn: nil))
            .drive(
                onNext: { [weak self] callInfo in
                    guard let self = self else {
                        return
                    }
                    
                    self.pushNotificationService.ignoreIncomingCall(withId: self.callPayload.uniqueIdentifier)
                    
                    guard let currentCall = callInfo?.0,
                        (currentCall.state == .Connected || currentCall.state == .StreamsRunning) else {
                        self.providerProxy.endCall(uuid: self.callPayload.uuid)
                        self.completionHandler?()
                        self.completionHandler = nil
                        self.router.trigger(.closeIncomingCall)
                        
                        return
                    }

                    do {
                        try currentCall.terminate()
                    } catch {
                        self.providerProxy.endCall(uuid: self.callPayload.uuid)
                        self.completionHandler?()
                        self.completionHandler = nil
                        self.router.trigger(.closeIncomingCall)
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: При изменении стейта sound output - включаем или выключаем громкоговоритель
        
        currentState
            .map { $0.soundOutputState }
            .distinctUntilChanged()
            .drive(
                onNext: { [weak self] state in
                    self?.setSpeakerEnabled(state == .speaker)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Отслеживание текущего output для звука
        // Нужно для того, чтобы при включении / выключении громкоговорителя с CallKit здесь обновлялся стейт
        
        NotificationCenter.default.rx
            .notification(AVAudioSession.routeChangeNotification)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(currentState)
            .drive(
                onNext: { [weak self] currentState in
                    guard currentState.doorState == .notDetermined,
                        currentState.soundOutputState != .disabled else {
                        return
                    }
                    
                    let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
                    let isSpeakerEnabled = outputs.contains { output in output.portType == .builtInSpeaker }
                    
                    let newState = IncomingCallStateContainer(
                        callState: currentState.callState,
                        doorState: currentState.doorState,
                        previewState: currentState.previewState,
                        soundOutputState: isSpeakerEnabled ? .speaker : .regular
                    )
                    self?.currentStateSubject.onNext(newState)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: При поднесении девайса к уху надо выключать громкоговоритель
        
        NotificationCenter.default.rx
            .notification(UIDevice.proximityStateDidChangeNotification)
            .asDriverOnErrorJustComplete()
            .map { _ in UIDevice.current.proximityState }
            .isTrue()
            .withLatestFrom(currentState)
            .drive(
                onNext: { [weak self] currentState in
                    guard currentState.doorState == .notDetermined,
                        currentState.soundOutputState != .disabled else {
                        return
                    }
                    
                    let newState = IncomingCallStateContainer(
                        callState: currentState.callState,
                        doorState: currentState.doorState,
                        previewState: currentState.previewState,
                        soundOutputState: .regular
                    )
                    
                    self?.currentStateSubject.onNext(newState)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: обработка выбранного пользователем в Push-notification действия(Открыть или Игнорировать)
        if ["OPEN_ACTION", "IGNORE_ACTION"].contains(self.actionIdentifier) {
            incomingCall
                .asDriverOnErrorJustComplete()
                .filter { callObject in
                    guard let call = callObject?.0 else {
                        return false
                    }
                    return call.state == .IncomingReceived
                }
                .drive(
                    onNext: { [weak self] _ in
                        guard let self = self else {
                            return
                        }
                        // Чтобы очистить уведомления о входящих вызовах, которые могли успеть прилететь,
                        // пока мы запускали приложение и регистрировались на сервере,
                        // хотелось сделать вот так:
                        // UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["voip"])
                        // Но почему-то удаление конкретных типов уведомлений по id не работает:
                        // response.notification.request.identifier не соответствует apns-collapse-id
                        //                         https://developer.apple.com/documentation/usernotifications/unnotificationrequest/1649634-identifier
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                        }
                        
                        switch self.actionIdentifier {
                        case "OPEN_ACTION":
                            DispatchQueue.main.async {
                                self.doorOpeningRequestedByUser.onNext(true)
                            }
                        case "IGNORE_ACTION":
                            DispatchQueue.main.async {
                                self.endCallProxySubject.onNext(())
                            }
                            
                        default:
                            break
                        }
                    }
                )
                .disposed(by: disposeBag)
        }
    }
    
    func transform(input: Input) -> Output {
        // MARK: Общий стейт экрана
        
        let currentState = currentStateSubject.asDriverOnErrorJustComplete()
        
        // MARK: проксируем нажатие кнопки "Открыть" в локальный сабжект
        // Заодно обновляем стейт на "Соединение...", если до этого был стейт "Входящий звонок"
        
        input.openTrigger
            .withLatestFrom(currentState)
            .drive(
                onNext: { [weak self] currentState in
                    if currentState.callState == .callReceived {
                        let newState = IncomingCallStateContainer(
                            callState: .establishingConnection,
                            doorState: currentState.doorState,
                            previewState: currentState.previewState,
                            soundOutputState: currentState.soundOutputState
                        )
                        self?.currentStateSubject.onNext(newState)
                    }
                    
                    self?.doorOpeningRequestedByUser.onNext(true)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Выставляем вьюхи для отображения видео
        
        input.videoViewsTrigger
            .drive(
                onNext: { [weak self] args in
                    let (videoView, cameraView) = args
                    
                    self?.linphoneService.setViews(videoView: videoView, cameraView: cameraView)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на кнопку "Звонок" во вьюхе приложения
        
        input.callTrigger
            .drive(
                onNext: { [weak self] in
                    self?.answerCallProxySubject.onNext(())
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на кнопку "Игнорировать / Отклонить"
        
        input.ignoreTrigger
            .drive(
                onNext: { [weak self] in
                    self?.endCallProxySubject.onNext(())
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на кнопку "Глазок"
        
        input.previewTrigger
            .withLatestFrom(currentState)
            .drive(
                onNext: { [weak self] currentState in
                    guard let self = self, currentState.doorState == .notDetermined else {
                        return
                    }
                    
                    let newState = IncomingCallStateContainer(
                        callState: currentState.callState,
                        doorState: currentState.doorState,
                        previewState: currentState.previewState == .staticImage ? .video : .staticImage,
                        soundOutputState: currentState.soundOutputState
                    )
                    
                    self.currentStateSubject.onNext(newState)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на кнопку "Динамик"
        
        input.speakerTrigger
            .withLatestFrom(currentState)
            .drive(
                onNext: { [weak self] currentState in
                    guard currentState.doorState == .notDetermined,
                        currentState.soundOutputState != .disabled else {
                        return
                    }
                    
                    let newState = IncomingCallStateContainer(
                        callState: currentState.callState,
                        doorState: currentState.doorState,
                        previewState: currentState.previewState,
                        soundOutputState: currentState.soundOutputState == .regular ? .speaker : .regular
                    )
                    
                    self?.currentStateSubject.onNext(newState)
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: При переходе в альбомный режим автоматически включается громкоговоритель
        // Если пользователь держит девайс близко к уху - НЕ включаем громкоговоритель
        
        input.viewWillAppear
            .filter { $0 == .landscape }
            .withLatestFrom(currentState)
            .drive(
                onNext: { [weak self] currentState in
                    guard currentState.doorState == .notDetermined,
                        currentState.soundOutputState != .disabled,
                        !UIDevice.current.proximityState else {
                        return
                    }
                    
                    let newState = IncomingCallStateContainer(
                        callState: currentState.callState,
                        doorState: currentState.doorState,
                        previewState: currentState.previewState,
                        soundOutputState: .speaker
                    )
                    
                    self?.currentStateSubject.onNext(newState)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            state: currentState,
            subtitle: subtitleSubject.asDriverOnErrorJustComplete(),
            image: imageSubject.asDriverOnErrorJustComplete(),
            isDoorBeingOpened: isDoorBeingOpened.asDriver(onErrorJustReturn: false)
        )
    }
    
    private func setSpeakerEnabled(_ enabled: Bool) {
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(enabled ? .speaker : .none)
        } catch {
            print("Couldn't switch output port")
        }
    }
    
    private func openTheDoor(call: Call) {
        isDoorBeingOpened.onNext(true)
        
        // MARK: Поскольку доставка тонового сигнала вообще не гарантируется, решено отправлять их несколько раз
        // С промежутком в 750 мс
        
        let dtmfRetrier = Driver<Int>
            .interval(.milliseconds(750))
        
        dtmfRetrier
            .filter { $0 < 3 }
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self,
                          call.state == .StreamsRunning
                    else {
                        return
                    }
                    
                    do {
                        try call.sendDtmfs(dtmfs: self.callPayload.dtmf)
                    } catch {
                        self.isDoorBeingOpened.onNext(false)
                        return
                    }
                }
            )
            .disposed(by: disposeBag)
        
        dtmfRetrier
            .filter { $0 >= 3 }
            .throttle(.never)
            .drive(
                onNext: { [weak self] _ in
                    print("DTMF code was sent. Delivery is not guaranteed tho")
                    
                    self?.isDoorBeingOpened.onNext(false)
                    
                    let newState = IncomingCallStateContainer(
                        callState: .callFinished,
                        doorState: .opened,
                        previewState: .staticImage,
                        soundOutputState: .disabled
                    )
                    self?.currentStateSubject.onNext(newState)
                    
                    do {
                        try call.terminate()
                    } catch {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                            guard let self = self else {
                                return
                            }
                            
                            self.providerProxy.endCall(uuid: self.callPayload.uuid)
                            self.completionHandler?()
                            self.completionHandler = nil
                            self.router.trigger(.closeIncomingCall)
                        }
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension IncomingCallViewModel: LinphoneDelegate {
    func onAccountRegistrationStateChanged(lc core: Core, account: Account, state: RegistrationState, message: String) {
        print("DEBUG / REGISTRATION STATE: \(state)")
        
        if state == .Ok {
            registrationFinished.onNext(true)
        }
    }
    
    func onCallStateChanged(lc: Core, call: Call, cstate: Call.State, message: String) {
        print("DEBUG / CALL STATE: \(cstate)")
        
        // обновляем режим вывода звука согласно текущего состояния, т.к. оно затирается при снятии трубки linphone-ом
        if cstate == .StreamsRunning,
            let soundOutputState = try? currentStateSubject.value().soundOutputState {
            setSpeakerEnabled(soundOutputState == .speaker)
        }
        
        if cstate == .IncomingReceived, let params = try? lc.createCallParams(call: call) {
            params.videoEnabled = true
            params.audioEnabled = true
            
            incomingCall.onNext((call, params))
        }
        
        if cstate == .End {
            if let currentState = try? currentStateSubject.value() {
                let newState = IncomingCallStateContainer(
                    callState: .callFinished,
                    doorState: currentState.doorState,
                    previewState: .staticImage,
                    soundOutputState: .disabled
                )
                
                currentStateSubject.onNext(newState)
            }
            
            providerProxy.endCall(uuid: callPayload.uuid)
            
            self.completionHandler?()
            self.completionHandler = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.router.trigger(.closeIncomingCall)
            }
        }
    }
    
}

extension IncomingCallViewModel: CXProviderProxyDelegate {
    
    func providerDidEndCall(_ provider: CXProvider) {
        endCallProxySubject.onNext(())
    }
    
    func providerDidAnswerCall(_ provider: CXProvider) {
        answerCallProxySubject.onNext(())
        NotificationCenter.default.post(name: .answeredByCallKit, object: nil)
        
    }
    
    func provider(_ provider: CXProvider, didActivateAudioSession audioSession: AVAudioSession) {
        linphoneService.core?.activateAudioSession(actived: true)
    }
    
    func provider(_ provider: CXProvider, didDeactivateAudioSession audioSession: AVAudioSession) {
        linphoneService.core?.activateAudioSession(actived: false)
    }
    
}
