//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by admin on 13/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UserNotifications

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
        
        let domophoneId: String? = {
            guard let domophoneId = request.content.userInfo["domophoneId"] as? String else {
                return nil
            }
            
            return "ID домофона: \(domophoneId)"
        }()
        
        let flatId: String? = {
            guard let flatId = request.content.userInfo["flatId"] as? String else {
                return nil
            }
            
            return "ID квартиры: \(flatId)"
        }()
        
        let body = [domophoneId, flatId].compactMap { $0 }.joined(separator: ". ")
        
        bestAttemptContent.body = body
        bestAttemptContent.sound = .default
        
        self.bestAttemptContent = bestAttemptContent
        
        // MARK: Удаление уведомлений происходит асинхронно, и иногда просто не успевает произойти до показа нового
        // Здесь, я подозреваю, нужно будет ресерчить и разруливать как-то менее костыльно. Пока не знаю как
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            contentHandler(bestAttemptContent)
        }
        
        // MARK: Грузится слишком долго (3+ секунды)
//        guard let image = request.content.userInfo["live"] as? String, let imageUrl = URL(string: image) else {
//            contentHandler(request.content)
//            return
//        }
//
//        store(imageUrl: imageUrl) { result in
//            if let path = try? result.get(),
//                let attachment = try? UNNotificationAttachment(
//                    identifier: imageUrl.absoluteString,
//                    url: path,
//                    options: nil
//                ) {
//                bestAttemptContent.attachments = [attachment]
//            }
//
//            contentHandler(bestAttemptContent)
//        }
    }
    
    private func store(imageUrl: URL, completion: ((Result<URL, Error>) -> Void)?) {
        let filename = ProcessInfo.processInfo.globallyUniqueString + imageUrl.lastPathComponent
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        
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
                try data.write(to: path)
                completion?(.success(path))
            } catch let error {
                completion?(.failure(error))
            }
        }
        task.resume()
    }

}
