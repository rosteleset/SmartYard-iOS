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
    case incomingCall(callPayload: CallPayload)
    case dismiss
    case userName
    case phoneNumber
    case pinCode(phoneNumber: String)
    
}

class AppCoordinator: NavigationCoordinator<AppRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let linphoneService = LinphoneService()
    private let apiService = APIService()
    private let accessService = AccessService()
    private let apiWrapper: APIWrapper
    
    private var mainTabBarRouter: StrongRouter<MainTabBarRoute>?
    
    private var currentCallPreviewData: Data?
    
    init() {
        // MARK: Замоканные данные. Убрать после добавления флоу авторизации
        accessService.accessToken = "79902143-88e4-46fd-a2ed-2bd0b132c433:6ebba629d6adbace8fbb974fd0aa4795"
        accessService.clientId = "75549"
        
        apiWrapper = APIWrapper(apiService: apiService, accessService: accessService)
        
        super.init(initialRoute: .phoneNumber)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
        
        AVCaptureDevice.requestAccess(for: .video) { _ in }
    }
    
    override func prepareTransition(for route: AppRoute) -> NavigationTransition {
        switch route {
        case .main:
            let router = MainTabBarCoordinator(
                apiWrapper: apiWrapper
            ).strongRouter
            
            mainTabBarRouter = router
            return .set([router])
            
        case let .incomingCall(callPayload):
            let vm = IncomingCallViewModel(
                linphoneService: linphoneService,
                callPayload: callPayload,
                router: weakRouter
            )
            
            let vc = IncomingCallViewController(viewModel: vm)
            vc.modalPresentationCapturesStatusBarAppearance = true
            
            return .present(vc, animation: .fade)
            
        case .dismiss:
            return .dismiss()
            
        case .userName:
            let vm = UserNameViewModel(router: weakRouter)
            let vc = UserNameViewController(viewModel: vm)
            return .present(vc)
            
        case .phoneNumber:
            let vm = InputPhoneNumberViewModel(router: weakRouter)
            return .present(InputPhoneNumberViewController(viewModel: vm))
           // return .present(AuthByContractNumViewController())
            
        case let .pinCode(phoneNumber):
            let vm = PinCodeViewModel(router: weakRouter, phoneNumber: phoneNumber)
            return .present(PinCodeViewController(viewModel: vm))
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
        switch UIApplication.shared.applicationState {
        case .active:
            trigger(.incomingCall(callPayload: callPayload))
        default:
            createIncomingCallNotification(withCallPayload: callPayload)
        }
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
