//
//  PushNotificationService.swift
//  SmartYard
//
//  Created by admin on 18/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import FirebaseMessaging

private let ignoredCallIdsKey = "ignoredCallIds"

final class PushNotificationService: HasDisposeBag {
    
    private let apiWrapper: APIWrapper
    
    private let userNotificationCenter = UNUserNotificationCenter.current()
    
    var ignoredCallIds: Set<String> {
        get {
            return UserDefaults.standard.object(Set<String>.self, with: ignoredCallIdsKey) ?? []
        }
        set {
            UserDefaults.standard.set(object: newValue, forKey: ignoredCallIdsKey)
        }
    }
    
    init(apiWrapper: APIWrapper) {
        self.apiWrapper = apiWrapper
    }
    
    func ignoreIncomingCall(withId callId: String) {
        var currentIgnoredCallIds = ignoredCallIds
        currentIgnoredCallIds.insert(callId)
        ignoredCallIds = currentIgnoredCallIds
    }
    
    func isCallIgnored(callId: String) -> Bool {
        return ignoredCallIds.contains(callId)
    }
    
    /// Удалит токен на РБТ. Переведет его в off. Более надежное решение при разлогине чем метод resetInstanceId.
    func deletePushToken() {
        apiWrapper.registerPushToken(
            pushToken: "",
            voipToken: nil,
            clientId: nil,
            type: .fcmRepeating
        )
        .subscribe(
            onSuccess: { _ in
                Logger.logDebug("Push token successfully reset on backend")
            },
            onFailure: { error in
                Logger.logDebug("Error resetting push token: \(error)")
            }
        )
        .disposed(by: disposeBag)
    }
    
    /// Сбрасывает InstanceId. Этакий способ гарантированно отписаться от уведомлений при разлогине
    func resetInstanceId() -> Single<Void?> {
        return Single.create { single in
            Messaging.messaging().deleteData { error in
                #if targetEnvironment(simulator)
                
                return single(.success(()))
                
                #else

                guard let error = error else {
                    single(.success(()))
                    return
                }
                
                let nsError = error as NSError
                
                if nsError.domain == "NSURLErrorDomain", nsError.code == -1009 {
                    single(.failure(NSError.PushNotificationServiceError.connectionRequired))
                } else {
                    single(.failure(error))
                }
                
                #endif
            }
            
            return Disposables.create()
        }
    }
    
    /// Подписка на уведомления. Если прокинуты оба токена, звонки будут идти через VoIP пуши
    func registerForPushNotifications(voipToken: String?) -> Single<Void?> {
        guard let fcmToken = Messaging.messaging().fcmToken else {
            return .error(NSError.PushNotificationServiceError.fcmTokenMissing)
        }
        
        Logger.logDebug("REGISTER WITH VOIP TOKEN \(String(describing: voipToken))")
        
        return apiWrapper.registerPushToken(
            pushToken: fcmToken,
            voipToken: voipToken,
            clientId: nil,
            type: .fcmRepeating
        )
    }
    
    /// Помечает все inbox message, которые сейчас есть в NotificationCenter, как доставленные (чтобы бэк не присылал их повторно)
    func markAllMessagesAsDelivered() {
        userNotificationCenter.getDeliveredNotifications { [weak self] notifications in
            let messageIds: [String] = notifications.compactMap { notification in
                guard let rawMessageType = notification.request.content.userInfo["messageType"] as? String,
                    let messageType = MessageType(rawValue: rawMessageType),
                    messageType == .inbox,
                    let messageId = notification.request.content.userInfo["messageId"] as? String else {
                    return nil
                }
                
                return messageId
            }
            
            DispatchQueue.main.async {
                self?.markMessagesAsDelivered(messageIds: messageIds)
            }
        }
    }

    /// Помечает inbox message с заданными messageId как доставленные (чтобы бэк не присылал их повторно)
    func markMessagesAsDelivered(messageIds: [String]) {
        // MARK: сейчас я не совсем представляю, как мне гарантировать отправку маркера на сервер
        // Сколько раз ретраить запрос и т.д.
        // Поэтому я просто создаю запросы на каждый пуш и выполняю их. Без разницы, какой будет результат
        
        let queries = messageIds.map { messageId in
            apiWrapper.delivered(messageId: messageId)
                .asDriver(onErrorJustReturn: nil)
                .map { (response: Void?) -> (String, Bool) in
                    (messageId, response != nil)
                }
        }
        
        Driver
            .concat(queries)
            .drive(
                onNext: { messageId, isMarked in
                    Logger.logDebug("📦 Message \(messageId) delivery state: \(isMarked ? "✅ Delivered" : "❌ Not marked")")
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// Удаляет все уведомления с заданным типом действия из Notification Center
    func deleteAllDeliveredNotifications(withActionType neededAction: MessageType) {
        userNotificationCenter.getDeliveredNotifications { [weak self] notifications in
            let notificationIds: [String] = notifications.compactMap { notification in
                guard let rawAction = notification.request.content.userInfo["action"] as? String,
                    let action = MessageType(rawValue: rawAction),
                    action == neededAction else {
                    return nil
                }
                
                return notification.request.identifier
            }
            
            self?.userNotificationCenter.removeDeliveredNotifications(withIdentifiers: notificationIds)
        }
    }
    
    /// Получает с сервера количество непрочитанных сообщений и обновляет Badge
    func synchronizeBadgeCount() {
        apiWrapper.unreaded()
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { response in
                    UIApplication.shared.applicationIconBadgeNumber = response.count + response.chat
                    
                    NotificationCenter.default.post(
                        // swiftlint:disable:next empty_count
                        name: response.count == 0 ? .allInboxMessagesRead : .unreadInboxMessagesAvailable,
                        object: nil
                    )
                    
                    NotificationCenter.default.post(
                        name: response.chat == 0 ? .allChatMessagesRead : .unreadChatMessagesAvailable,
                        object: nil
                    )
                }
            )
            .disposed(by: disposeBag)
    }
    
}

struct ParanoidPushPayload: Equatable {
    let title: String
    let body: String
    let date: String
    let hash: String?
    let imageUrl: String?

    init?(
        userInfo: [AnyHashable: Any],
        notificationTitle: String?,
        notificationBody: String?,
        providerBaseURL: String,
        serverTimeZone: String,
        now: Date = Date()
    ) {
        guard Self.isParanoidAction(userInfo) else { return nil }

        title = Self.stringValue(for: "title", in: userInfo)
            ?? Self.stringValue(for: "gcm.notification.title", in: userInfo)
            ?? Self.alertValue(for: "title", in: userInfo)
            ?? notificationTitle
            ?? ""

        body = Self.stringValue(for: "body", in: userInfo)
            ?? Self.stringValue(for: "gcm.notification.body", in: userInfo)
            ?? Self.alertValue(for: "body", in: userInfo)
            ?? notificationBody
            ?? ""

        hash = Self.stringValue(for: "hash", in: userInfo)
        imageUrl = hash.map { Self.imageURL(providerBaseURL: providerBaseURL, hash: $0) }
        date = Self.formattedDate(
            timestamp: userInfo["timestamp"],
            serverTimeZone: serverTimeZone,
            now: now
        )
    }

    static func isParanoidAction(_ userInfo: [AnyHashable: Any]) -> Bool {
        return stringValue(for: "action", in: userInfo) == "paranoid"
    }

    static func keyValuePayload(
        userInfo: [AnyHashable: Any],
        providerBaseURL: String,
        serverTimeZone: String,
        now: Date = Date()
    ) -> ParanoidPushPayload? {
        return ParanoidPushPayload(
            userInfo: userInfo,
            notificationTitle: nil,
            notificationBody: nil,
            providerBaseURL: providerBaseURL,
            serverTimeZone: serverTimeZone,
            now: now
        )
    }

    static func imageURL(providerBaseURL: String, hash: String) -> String {
        let separator = providerBaseURL.hasSuffix("/") ? "" : "/"
        return providerBaseURL + separator + "call/camshot/" + hash
    }

    static func formattedDate(
        timestamp: Any?,
        serverTimeZone: String,
        now: Date = Date()
    ) -> String {
        let date: Date = {
            guard let seconds = unixSeconds(from: timestamp) else { return now }
            return Date(timeIntervalSince1970: TimeInterval(seconds))
        }()

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU_POSIX")
        formatter.timeZone = TimeZone(identifier: serverTimeZone) ?? TimeZone.current
        formatter.dateFormat = "dd.MM.yyyy, HH:mm:ss"
        return formatter.string(from: date)
    }

    private static func unixSeconds(from timestamp: Any?) -> Int64? {
        switch timestamp {
        case let value as Int:
            return Int64(value)
        case let value as Int64:
            return value
        case let value as Double:
            return Int64(value)
        case let value as String:
            return Int64(value)
        default:
            return nil
        }
    }

    private static func stringValue(for key: String, in userInfo: [AnyHashable: Any]) -> String? {
        return userInfo[key] as? String
    }

    private static func alertValue(for key: String, in userInfo: [AnyHashable: Any]) -> String? {
        guard let aps = userInfo["aps"] as? [AnyHashable: Any] else { return nil }

        if let alert = aps["alert"] as? [AnyHashable: Any] {
            return alert[key] as? String
        }

        if key == "body",
           let alert = aps["alert"] as? String {
            return alert
        }

        return nil
    }
}

#if DEBUG
enum ParanoidFeatureChecks {
    private static var hasRun = false

    static func run() {
        guard !hasRun else { return }
        hasRun = true

        let keyDetail = DetailX(
            key: "rfid-key",
            face: nil,
            flags: nil,
            phone: nil,
            code: nil,
            faceId: nil
        )
        let appDetail = DetailX(
            key: nil,
            face: nil,
            flags: nil,
            phone: "+79990000000",
            code: nil,
            faceId: nil
        )
        let plateDetail = DetailX(
            key: nil,
            face: nil,
            flags: nil,
            phone: nil,
            code: nil,
            faceId: nil,
            vehicle: .init(vehicleBox: nil, plateKeyPoints: nil, plateNumber: "A123AA")
        )

        let keyEvent = makeEvent(flatId: 7, event: .rfid, detailX: keyDetail)
        let appEvent = makeEvent(flatId: 7, event: .app, detailX: appDetail)
        let codeEvent = makeEvent(flatId: 7, event: .passcode, detailX: nil)
        let plateEvent = makeEvent(flatId: 7, event: .plate, detailX: plateDetail)

        assert(ParanoidEventTracking.eventDetail(from: keyEvent) == "rfid-key")
        assert(ParanoidEventTracking.eventDetail(from: appEvent) == "+79990000000")
        assert(ParanoidEventTracking.eventDetail(from: codeEvent) == "")
        assert(ParanoidEventTracking.eventDetail(from: plateEvent) == "A123AA")
        assert(ParanoidEventTracking.key(for: plateEvent) == "7_9_A123AA")

        let trackRequest = TrackEventRequest(
            accessToken: "token",
            flatId: 7,
            eventType: 9,
            eventDetail: "A123AA",
            comments: "comment"
        )
        assert(trackRequest.requestParameters["flatId"] as? Int == 7)
        assert(trackRequest.requestParameters["eventType"] as? Int == 9)
        assert(trackRequest.requestParameters["eventDetail"] as? String == "A123AA")
        assert(trackRequest.requestParameters["comments"] as? String == "comment")

        let payload = ParanoidPushPayload(
            userInfo: [
                "action": "paranoid",
                "timestamp": "1700000000",
                "hash": "hash",
                "aps": ["alert": ["title": "Title", "body": "Body"]]
            ],
            notificationTitle: nil,
            notificationBody: nil,
            providerBaseURL: "https://example.com/mobile/",
            serverTimeZone: "Europe/Moscow",
            now: Date(timeIntervalSince1970: 0)
        )

        assert(payload?.title == "Title")
        assert(payload?.body == "Body")
        assert(payload?.date == "15.11.2023, 01:13:20")
        assert(payload?.imageUrl == "https://example.com/mobile/call/camshot/hash")
    }

    private static func makeEvent(
        flatId: Int,
        event: APIPlog.EventType,
        detailX: DetailX?
    ) -> APIPlog {
        return APIPlog(
            date: Date(timeIntervalSince1970: 0),
            uuid: UUID().uuidString,
            imageUuid: nil,
            flatId: flatId,
            objectId: 1,
            objectType: 0,
            objectMechanizma: 0,
            mechanizmaDescription: "",
            houseId: nil,
            entranceId: nil,
            cameraId: nil,
            event: event,
            detail: "",
            detailX: detailX,
            previewURL: nil,
            previewImage: nil
        )
    }
}
#endif
