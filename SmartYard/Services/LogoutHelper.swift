//
//  LogoutHelper.swift
//  SmartYard
//
//  Created by admin on 25.05.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SmartYardSharedDataFramework

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
        let okAction = UIAlertAction(title: "ОК", style: .destructive) { [weak self] _ in
            guard let self = self else {
                return
            }
            
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
            title: "Произведена авторизация на другом устройстве",
            message: nil,
            actions: [okAction],
            priority: 1000
        )
    }
    
}
