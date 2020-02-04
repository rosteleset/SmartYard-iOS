//
//  AppCoordinator.swift
//  SmartYard
//
//  Created by admin on 28/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import XCoordinator
import AVKit
import RxSwift
import RxCocoa
import Kingfisher
import UserNotifications
import linphonesw

enum AppRoute: Route {
    
    case main
    case incomingCall(callPayload: CallPayload, call: Call)
    
}

class AppCoordinator: NavigationCoordinator<AppRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let linphoneService = LinphoneService()
    private let apiService = APIService()
    private let accessService = AccessService()
    private let apiWrapper: APIWrapper
    
    private var currentCallPreviewData: Data?
    private var currentCallPayload: CallPayload?
    private var currentCall: Call?
    
    init() {
        // MARK: Замоканные данные. Убрать после добавления флоу авторизации
        accessService.accessToken = "79902143-88e4-46fd-a2ed-2bd0b132c433:6ebba629d6adbace8fbb974fd0aa4795"
        accessService.clientId = "75549"
        
        apiWrapper = APIWrapper(apiService: apiService, accessService: accessService)
        
        super.init(initialRoute: .main)
        rootViewController.setNavigationBarHidden(true, animated: false)
        
        AVCaptureDevice.requestAccess(for: .video) { _ in }
    }
    
    override func prepareTransition(for route: AppRoute) -> NavigationTransition {
        switch route {
        case .main:
            return .none()
            
        case let .incomingCall(callPayload, call):
            let vm = IncomingCallPreviewViewModel(
                linphoneService: linphoneService,
                callPayload: callPayload,
                call: call
            )
            
            let vc = IncomingCallPreviewViewController(viewModel: vm)
            return .present(vc, animation: .fade)
        }
    }
    
    func activateToken(token: String, tokenType: TokenType) {
        Completable
            .concat(
                apiWrapper.registerToken(pushToken: token, type: tokenType),
                apiWrapper.updateTokenState(pushToken: token, newState: .on)
            )
            .andThen(
                apiWrapper.checkTokenState(pushToken: token)
            )
            .subscribe(
                onSuccess: { data in
                    print("DEBUG / \(tokenType) \(token) is now \(data.state)")
                },
                onError: { error in
                    print(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
    func processCallRequest(
        callPayload: CallPayload,
        completion: @escaping () -> Void
    ) {
        // MARK: Если на данный момент уже есть звонок, то пока ничего не делаем (хз какая будет логика)
        guard currentCallPayload == nil, currentCall == nil else {
            print("DEBUG / ANOTHER INCOMING CALL / CAN'T ACCEPT TWO CALLS AT ONCE")
            completion()
            return
        }

        currentCallPayload = callPayload

        linphoneService.delegate = self
        linphoneService.connect(config: callPayload.sipConfig, videoView: UIView(), cameraView: UIView())
    }
    
    func showIncomingCall() {
        guard let callPayload = currentCallPayload, let call = currentCall else {
            return
        }
        
        trigger(.incomingCall(callPayload: callPayload, call: call))
    }
    
    // MARK: Создание картинки-превью для Push-уведомления
    // UNNotificationAttachment работает только с локальными файлами, использованная картинка при этом удаляется
    // Поэтому для начала нам надо записать скачанную картинку как png файл на диск
    private func createNotificationAttachment(fromPngData pngData: Data) -> UNNotificationAttachment? {
        guard let imgTarget = FileManager.default
            .urls(for: .libraryDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("DomophonePreview\(UUID().uuidString).png"),
            (try? pngData.write(to: imgTarget)) != nil,
            let attachment = try? UNNotificationAttachment(
                identifier: "DomophonePreview",
                url: imgTarget,
                options: nil
            ) else {
            return nil
        }
        
        return attachment
    }
    
    private func createIncomingCallNotification(withCallPayload callPayload: CallPayload) {
        let content = UNMutableNotificationContent()
        
        content.title = "Звонок в домофон"
        
        content.body = [callPayload.domophoneString, callPayload.flatString]
            .compactMap { $0 }
            .joined(separator: ". ")
        
        content.sound = UNNotificationSound.default
        content.userInfo = callPayload.asPushNotificationPayload
        
        let finishHandler = { [weak self] in
            let request = UNNotificationRequest(
                identifier: "IncomingCall",
                content: content,
                trigger: nil
            )
            
            self?.notificationCenter.add(request, withCompletionHandler: nil)
        }
        
        guard let url = URL(string: callPayload.liveImage) else {
            finishHandler()
            return
        }
        
        KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
            guard let imageResult = try? result.get(),
                let pngData = imageResult.image.pngData(),
                let attachment = self?.createNotificationAttachment(fromPngData: pngData) else {
                finishHandler()
                return
            }
            
            self?.currentCallPreviewData = pngData
            content.attachments = [attachment]
            finishHandler()
        }
    }
    
    private func updateIncomingCallNotificationToMissed() {
        notificationCenter.getDeliveredNotifications { [weak self] notifications in
            // MARK: Если есть уведомление о входящем вызове, находим его и берем его контент
            
            let incomingCallContent = notifications
                .first { $0.request.identifier == "IncomingCall" }?
                .request
                .content
            
            // MARK: Удаляем уведомление о входящем вызове
            // Обязательно нужно удалить старое уведомление до создания нового
            // Иначе какой-то внутренний кэш не позволит создать уведомление с той же самой превью-картинкой
            
            self?.notificationCenter
                .removeDeliveredNotifications(withIdentifiers: ["IncomingCall"])
            
            // MARK: Создаем контент для нового уведомления из частей старого
            
            let newContent = UNMutableNotificationContent()
            newContent.title = "Пропущенный звонок"
            newContent.body = incomingCallContent?.body ?? ""
            
            if let pngData = self?.currentCallPreviewData,
                let attachment = self?.createNotificationAttachment(fromPngData: pngData) {
                newContent.attachments = [attachment]
            }
            
            let newRequest = UNNotificationRequest(
                identifier: "MissedCall" + UUID().uuidString,
                content: newContent,
                trigger: nil
            )
            
            // MARK: И создаем уведомление о пропущенном вызове
            
            self?.notificationCenter.add(newRequest, withCompletionHandler: nil)
        }
    }
    
}

extension AppCoordinator: LinphoneDelegate {
    
    func onRegistrationStateChanged(lc: Core, cfg: ProxyConfig, cstate: RegistrationState, message: String) {
        print("DEBUG / REGISTRATION STATE: \(cstate)")
    }
    
    func onCallStateChanged(lc: Core, call: Call, cstate: Call.State, message: String) {
        print("DEBUG / CALL STATE: \(cstate)")
        
        switch cstate {
        // MARK: При поступлении входящего звонка создаем для пользователя локальное уведомление
        // Либо сразу показываем входящий вызов, если находимся в foreground
        case .IncomingReceived:
            guard let callPayload = currentCallPayload else {
                fatalError("CALL PAYLOAD WAS SOMEHOW DELETED")
            }
            
            currentCall = call
            
            switch UIApplication.shared.applicationState {
            case .active:
                showIncomingCall()
            default:
                createIncomingCallNotification(withCallPayload: callPayload)
            }
        
        // MARK: При завершении звонка - заменяем это уведомление на "Пропущенный звонок"
        // TODO: Отработать кейс, когда звонок будет принят и завершится успешно (не нужно показывать пропущенный)
        // TODO: Отработать кейс, когда звонок не будет сброшен за 30 секунд (нужно показать пропущенный)
        case .End:
            updateIncomingCallNotificationToMissed()
            
            currentCallPayload = nil
            currentCall = nil
        default:
            break
        }
    }
    
}
