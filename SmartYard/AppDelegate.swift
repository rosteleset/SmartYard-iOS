//
//  AppDelegate.swift
//  SmartYard
//
//  Created by admin on 28/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import Firebase
import PushKit
import Kingfisher
import Alamofire
import linphonesw
import AVKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private lazy var mainWindow = UIWindow()
    
    private let appCoordinator = AppCoordinator()
    private let apiService = APIService()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureFirebase(for: application)
        configureVoIPNotifications()
        AVCaptureDevice.requestAccess(for: .video) { _ in }
        
        appCoordinator.setRoot(for: mainWindow)
        
        return true
    }
    
    private func configureFirebase(for application: UIApplication) {
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in })
        
        application.registerForRemoteNotifications()
    }

}

// MARK: VoIP Notifications

extension AppDelegate: PKPushRegistryDelegate {
    
    private func configureVoIPNotifications() {
        let registry = PKPushRegistry(queue: DispatchQueue.main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        print(token)
        
        apiService.performSendTokenRequest(
            SendTokenRequest(login: "f70392", password: "d342a76ec", token: token, tokenType: .apnsDebug)
        ) { result in
            print(result)
        }
        
        
//        sendTokenToBackend(token: token) { [weak self] result in
//            guard result.value == true else {
//                return
//            }
//
//            self?.enableTokenOnBackend(token: token) { result in
//                guard result.value == true else {
//                    return
//                }
//
//                self?.checkTokenOnBackend(token: token) { result in
//                    switch result {
//                    case .success(let value): print("DEBUG / IS TOKEN ACTIVE : \(value)")
//                    case .failure(let error): print(error.localizedDescription)
//                    }
//                }
//            }
//        }
    }
    
    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        print(payload.dictionaryPayload)
        
        guard let data = payload.dictionaryPayload["data"] as? [AnyHashable: Any],
            let username = data["extension"] as? String,
            let password = data["pass"] as? String,
            let server = data["server"] as? String,
            let port = data["port"] as? String,
            let rawTransport = data["transport"] as? String,
            let liveImage = data["live"] as? String else {
                completion()
                return
        }
        
        let domophoneId: String? = {
            guard let domophoneId = data["domophone_id"] as? String else {
                return nil
            }
            
            return "ID домофона: \(domophoneId)"
        }()
        
        let flatId: String? = {
            guard let flatId = data["flat_id"] as? String else {
                return nil
            }
            
            return "ID квартиры: \(flatId)"
        }()
        
        let content = UNMutableNotificationContent()
        
        content.title = "Звонок в домофон"
        content.body = [domophoneId, flatId].compactMap { $0 }.joined(separator: ". ")
        content.sound = UNNotificationSound.default
        
        content.userInfo = [
            "extension": username,
            "pass": password,
            "server": server,
            "port": port,
            "rawTransport": rawTransport,
            "live": liveImage
        ]
        
        let finishHandler = {
            let request = UNNotificationRequest(
                identifier: "IncomingCall",
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter
                .current()
                .add(request, withCompletionHandler: nil)
            
            completion()
        }
        
        guard let url = URL(string: liveImage) else {
            finishHandler()
            return
        }
        
        KingfisherManager.shared.retrieveImage(with: url) { result in
            guard let imageResult = try? result.get(),
                let pngData = imageResult.image.pngData(),
                let imgTarget = FileManager.default
                    .urls(for: .libraryDirectory, in: .userDomainMask)
                    .first?
                    .appendingPathComponent("DomophonePreview.png"),
                let _ = try? pngData.write(to: imgTarget),
                let attachment = try? UNNotificationAttachment(
                    identifier: "DomophonePreview",
                    url: imgTarget,
                    options: nil
                ) else {
                    finishHandler()
                    return
            }
            
            content.attachments = [attachment]
            finishHandler()
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let request = response.notification.request
        
        if request.identifier == "IncomingCall" {
            // Показать окно с глазком или еще что-то
        }
        
        completionHandler()
    }
    
}

// MARK: Push Notifications

extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        if let messageID = userInfo["gcm.message_id"] {
            print("DEBUG / PUSH NOTIFICATIONS / Message ID: \(messageID)")
        }
        
        print("DEBUG / PUSH NOTIFICATIONS / User Info: \(userInfo)")
        
        guard let config = extractConfigFromData(userInfo) else {
            return
        }
        
        NotificationCenter.default.post(
            name: .init("receivedConfigFromPushNotification"),
            object: nil,
            userInfo: ["config": config]
        )
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
        ) {
        if let messageID = userInfo["gcm.message_id"] {
            print("DEBUG / PUSH NOTIFICATIONS / Message ID: \(messageID)")
        }
        
        print("DEBUG / PUSH NOTIFICATIONS / User Info: \(userInfo)")
        
        guard let config = extractConfigFromData(userInfo) else {
            completionHandler(.newData)
            return
        }
        
        NotificationCenter.default.post(
            name: .init("receivedConfigFromPushNotification"),
            object: nil,
            userInfo: ["config": config]
        )
        
        completionHandler(.newData)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("DEBUG / PUSH NOTIFICATIONS / Firebase registration token: \(fcmToken)")
        
        //        sendTokenToBackend(token: fcmToken) { [weak self] result in
        //            guard result.value == true else {
        //                return
        //            }
        //
        //            self?.enableTokenOnBackend(token: fcmToken) { result in
        //                guard result.value == true else {
        //                    return
        //                }
        //
        //                self?.checkTokenOnBackend(token: fcmToken) { result in
        //                    switch result {
        //                    case .success(let value): print("DEBUG / IS TOKEN ACTIVE : \(value)")
        //                    case .failure(let error): print(error.localizedDescription)
        //                    }
        //                }
        //            }
        //        }
    }
    
    private func sendTokenToBackend(token: String, completion: ((Result<Bool>) -> Void)?) {
        let endpointUrl = "https://dm.lanta.me/api"
        let login = "f70392"
        let password = "d342a76ec"
        
        let parameters: [String: Any] = [
            "action": "token_register",
            "type": 2,
            "login": login,
            "password": password,
            "token": token
        ]
        
        Alamofire
            .request(
                endpointUrl,
                method: .post,
                parameters: parameters,
                encoding: URLEncoding(destination: .queryString),
                headers: nil
            )
            .responseJSON { response in
                switch response.result {
                case .success(let json):
                    guard let dict = json as? [String: Any], let code = dict["code"] as? Int, code == 200 else {
                        completion?(.success(false))
                        return
                    }
                    
                    completion?(.success(true))
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
        }
    }
    
    private func enableTokenOnBackend(token: String, completion: ((Result<Bool>) -> Void)?) {
        let endpointUrl = "https://dm.lanta.me/api"
        let login = "f70392"
        let password = "d342a76ec"
        
        let parameters: [String: Any] = [
            "action": "token_intercom",
            "login": login,
            "password": password,
            "token": token,
            "enable": 1
        ]
        
        Alamofire
            .request(
                endpointUrl,
                method: .post,
                parameters: parameters,
                encoding: URLEncoding(destination: .queryString),
                headers: nil
            )
            .responseJSON { response in
                switch response.result {
                case .success(let json):
                    guard let dict = json as? [String: Any], let code = dict["code"] as? Int, code == 200 else {
                        completion?(.success(false))
                        return
                    }
                    
                    completion?(.success(true))
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
        }
    }
    
    private func checkTokenOnBackend(token: String, completion: ((Result<Bool>) -> Void)?) {
        let endpointUrl = "https://dm.lanta.me/api"
        let login = "f70392"
        let password = "d342a76ec"
        
        let parameters: [String: Any] = [
            "action": "token_intercom",
            "login": login,
            "password": password,
            "token": token
        ]
        
        Alamofire
            .request(
                endpointUrl,
                method: .post,
                parameters: parameters,
                encoding: URLEncoding(destination: .queryString),
                headers: nil
            )
            .responseJSON { response in
                switch response.result {
                case .success(let json):
                    guard let dict = json as? [String: Any], let code = dict["code"] as? Int, code == 200 else {
                        completion?(.success(false))
                        return
                    }
                    
                    completion?(.success(true))
                    
                case .failure(let error):
                    completion?(.failure(error))
                }
        }
    }
    
    private func extractConfigFromData(_ data: [AnyHashable: Any]) -> SipConfig? {
        guard let username = data["extension"] as? String,
            let password = data["pass"] as? String,
            let server = data["server"] as? String,
            let port = data["port"] as? String,
            let rawTransport = data["transport"] as? String else {
                return nil
        }
        
        let transport: TransportType? = {
            switch rawTransport {
            case "udp": return .Udp
            case "tcp": return .Tcp
            case "tls": return .Tls
            default: return nil
            }
        }()
        
        guard let unwrappedTransport = transport else {
            return nil
        }
        
        let domain = "\(server):\(port)"
        
        return SipConfig(
            domain: domain,
            username: username,
            password: password,
            transport: unwrappedTransport
        )
    }
    
}
