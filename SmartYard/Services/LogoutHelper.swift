//
//  LogoutHelper.swift
//  SmartYard
//
//  Created by admin on 25.05.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SmartYardSharedDataFramework
import FirebaseMessaging

// Есть таск - при получении 401 ошибки отправлять пользователя на логаут
// Изначально был вариант отслеживать получение 401 прямо в ApiWrapper и кидать оттуда notification
// В итоге этот вариант был отклонен по нескольким причинам
// 1) он очень грязный
// 2) мы можем получить 401 еще на этапе подтверждения кода (до авторизации)
// Было решено разруливать логаут в каждой вьюмодели отдельно. Копипаста, но более гибкая
// На всякий случай также происходит отписка от пушей (не знаю, разрулено ли это сервером)

class LogoutHelper {
    
    private let pushNotificationService: PushNotificationService
    private let accessService: AccessService
    private let alertService: AlertService
    
    init(
        pushNotificationService: PushNotificationService,
        accessService: AccessService,
        alertService: AlertService
    ) {
        self.pushNotificationService = pushNotificationService
        self.accessService = accessService
        self.alertService = alertService
    }
    
    func showAuthErrorAlert(
        activityTracker: ActivityTracker,
        errorTracker: ErrorTracker,
        disposeBag: DisposeBag
    ) {
        let okAction = UIAlertAction(title: "OK", style: .destructive) { [weak self] _ in
            guard let self = self else {
                return
            }
            
            Messaging.messaging().isAutoInitEnabled = false
            self.pushNotificationService.deletePushToken()
            self.pushNotificationService.resetInstanceId()
                .trackActivity(activityTracker)
                .trackError(errorTracker)
                .asDriver(onErrorJustReturn: nil)
                .ignoreNil()
                .drive(
                    onNext: { [weak self] in
                        SmartYardSharedDataUtilities.clearSharedData()
                        self?.accessService.logout()
                    }
                )
                .disposed(by: disposeBag)
        }
        
        alertService.showDialog(
            title: NSLocalizedString("Attention", comment: "") + "!",
            message: NSLocalizedString("You have been authorized on another device", comment: ""),
            actions: [okAction],
            priority: 1000
        )
    }
    
}
