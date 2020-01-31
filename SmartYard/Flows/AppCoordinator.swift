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
    private let apiWrapper: APIWrapper
    
    private var currentCallPreviewData: Data?
    private var currentCallPreviewURL: URL?
    private var currentCallPayload: CallPayload?
    private var currentCall: Call?
    
    init() {
        apiWrapper = APIWrapper(apiService: apiService)
        
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
                apiWrapper.sendToken(token: token, tokenType: tokenType),
                apiWrapper.updateTokenState(token: token, isEnabled: true),
                apiWrapper.checkTokenState(token: token)
            )
            .subscribe(
                onCompleted: {
                    print("DEBUG / \(tokenType) \(token) is now ACTIVE")
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
        guard currentCallPayload == nil, currentCall == nil else {
            print("Has incoming call already")
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
    
    private func createIncomingCallNotification() {
        guard let callPayload = currentCallPayload else {
            return
        }
        
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
                let imgTarget = FileManager.default
                    .urls(for: .cachesDirectory, in: .userDomainMask)
                    .first?
                    .appendingPathComponent("DomophonePreview\(UUID().uuidString).png"),
                (try? pngData.write(to: imgTarget)) != nil,
                let attachment = try? UNNotificationAttachment(
                    identifier: "DomophonePreview",
                    url: imgTarget,
                    options: nil
                ) else {
                finishHandler()
                return
            }
            
            self?.currentCallPreviewData = pngData
            self?.currentCallPreviewURL = imgTarget
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
            
            self?.notificationCenter
                .removeDeliveredNotifications(withIdentifiers: ["IncomingCall"])
            
            // MARK: Создаем контент для нового уведомления из частей старого
            
            let newContent = UNMutableNotificationContent()
            newContent.title = "Пропущенный звонок"
            newContent.body = incomingCallContent?.body ?? ""
            
            if let imgTarget = FileManager.default
                .urls(for: .libraryDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent("DomophonePreview\(UUID().uuidString).png"),
                let pngData = self?.currentCallPreviewData,
                (try? pngData.write(to: imgTarget)) != nil,
                let attachment = try? UNNotificationAttachment(
                    identifier: "DomophonePreviewwww",
                    url: imgTarget,
                    options: nil
                ) {
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
        print(cstate)
    }
    
    func onCallStateChanged(lc: Core, call: Call, cstate: Call.State, message: String) {
        print(cstate)
        
        switch cstate {
        case .IncomingReceived:
            createIncomingCallNotification()
                        
            currentCall = call
            
        case .End:
            updateIncomingCallNotificationToMissed()
            
            currentCallPayload = nil
            currentCall = nil
        default:
            break
        }
    }
    
}
