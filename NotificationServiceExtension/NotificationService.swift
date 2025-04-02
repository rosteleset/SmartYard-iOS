//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by admin on 13/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UserNotifications
import SmartYardSharedDataFramework

class NotificationService: UNNotificationServiceExtension {

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        parseIncomingCallNotificationRequest(request, withContentHandler: contentHandler)
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func parseIncomingCallNotificationRequest(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        // TODO: Сделать по-человечески
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }
        
        bestAttemptContent.title = "Звонок в домофон"
        bestAttemptContent.body = request.content.userInfo["callerId"] as? String ?? ""
        bestAttemptContent.body += "\n\n(нажмите и удерживайте для быстрого ответа)"
        bestAttemptContent.sound = .default
        bestAttemptContent.categoryIdentifier = "INCOMING_DOOR_CALL"
        if #available(iOS 15.0, *) {
            bestAttemptContent.interruptionLevel = .timeSensitive
        } else {
            // Fallback on earlier versions
        }
        
        self.bestAttemptContent = bestAttemptContent
        
        let sharedData = SmartYardSharedDataUtilities.loadSharedData()
        
        let hash = bestAttemptContent.userInfo["hash"] as? String
        let image = bestAttemptContent.userInfo["image"] as? String
        
        var imageUrlString: String?
        
        if let sharedData = sharedData,
           let backendURL = sharedData.backendURL,
           let hash = hash {
            imageUrlString = "\(backendURL)/call/camshot/\(hash)"
        } else {
            imageUrlString = image
        }
            
        // MARK: Грузится слишком долго (3+ секунды)
        guard let image = imageUrlString, let imageUrl = URL(string: image) else {
            // MARK: Удаление уведомлений происходит асинхронно, и иногда просто не успевает произойти до показа нового
            // Здесь, я подозреваю, нужно будет ресерчить и разруливать как-то менее костыльно. Пока не знаю как
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                contentHandler(bestAttemptContent)
            }
            
            return
        }

        store(imageUrl: imageUrl) { result in
            if let path = try? result.get(),
                let attachment = try? UNNotificationAttachment(
                    identifier: imageUrl.absoluteString,
                    url: path,
                    options: nil
                ) {
                bestAttemptContent.attachments = [attachment]
            }

            contentHandler(bestAttemptContent)
        }
    }
    
    private func store(imageUrl: URL, completion: ((Result<URL, Error>) -> Void)?) {
        let task = URLSession.shared.dataTask(with: imageUrl) { data, _, error in
            if let error = error {
                completion?(.failure(error))
                return
            }
            
            guard let data = data else {
                completion?(.failure(NSError(domain: "NotificationServiceExtension", code: 1, userInfo: nil)))
                return
            }
            
            do {
                // Если URL не содержит расширения файла, то iOS не понимает тип файла 🤦‍♂️
                let filename = ProcessInfo.processInfo.globallyUniqueString + imageUrl.lastPathComponent
                + ( imageUrl.pathExtension.isEmpty ? data.fileExt : "" )
                let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
                
                try data.write(to: path)
                completion?(.success(path))
            } catch let error {
                completion?(.failure(error))
            }
        }
        task.resume()
    }
    
}

extension Data {
    var fileExt: String {
        switch self[0] {
        case 0x89:
            return ".png"
        case 0xFF:
            return ".jpg"
        case 0x47:
            return ".gif"
        default:
            return ""
        }
    }
}
