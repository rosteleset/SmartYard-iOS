//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by admin on 13/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        // TODO: Сделать по-человечески. Нужно содействие с бэком
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        self.contentHandler = contentHandler
        
        guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }
        
        guard let image = request.content.userInfo["live"] as? String, let imageUrl = URL(string: image) else {
            contentHandler(request.content)
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
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
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
